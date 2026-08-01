#import "VCamHook.h"
#import "VCamRenderer.h"
#import "VCamConfig.h"
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <os/log.h>
#import <substrate.h>

static os_log_t vcamLog;
static NSMutableSet *hookedClasses;
static uint64_t renderedFrameCount = 0;

#pragma mark - Original Method IMPs

typedef void (*RenderSampleBufferIMP)(id, SEL, CMSampleBufferRef, NSInteger);
typedef void (*EmitSampleBufferIMP)(id, SEL, CMSampleBufferRef);

// Storage for original implementations per class
static NSMutableDictionary<NSString *, NSValue *> *origRenderIMPs;
static NSMutableDictionary<NSString *, NSValue *> *origEmitIMPs;

#pragma mark - Hook: renderSampleBuffer:forInput:

static void hooked_renderSampleBuffer_forInput(id self, SEL _cmd, CMSampleBufferRef sampleBuffer, NSInteger input) {
    NSString *className = NSStringFromClass([self class]);
    
    VCamConfig *config = [VCamConfig sharedConfig];
    if (!config.injectionEnabled) {
        // Pass through original
        NSValue *impVal = origRenderIMPs[className];
        if (!impVal) {
            // Walk superclass chain
            Class cls = [self class];
            while (cls) {
                NSString *name = NSStringFromClass(cls);
                impVal = origRenderIMPs[name];
                if (impVal) break;
                cls = class_getSuperclass(cls);
            }
        }
        if (impVal) {
            RenderSampleBufferIMP orig = (RenderSampleBufferIMP)[impVal pointerValue];
            orig(self, _cmd, sampleBuffer, input);
        }
        return;
    }
    
    // Replace the sample buffer with virtual frame
    CMSampleBufferRef replacedBuffer = [[VCamRenderer sharedRenderer]
                                         renderReplacementForSampleBuffer:sampleBuffer
                                         purpose:input];
    
    if (replacedBuffer) {
        renderedFrameCount++;
        
        // Call original with replaced buffer
        NSValue *impVal = origRenderIMPs[className];
        if (!impVal) {
            Class cls = [self class];
            while (cls) {
                NSString *name = NSStringFromClass(cls);
                impVal = origRenderIMPs[name];
                if (impVal) break;
                cls = class_getSuperclass(cls);
            }
        }
        if (impVal) {
            RenderSampleBufferIMP orig = (RenderSampleBufferIMP)[impVal pointerValue];
            orig(self, _cmd, replacedBuffer, input);
        }
        CFRelease(replacedBuffer);
    } else {
        // Fallback: pass through original
        NSValue *impVal = origRenderIMPs[className];
        if (!impVal) {
            Class cls = [self class];
            while (cls) {
                NSString *name = NSStringFromClass(cls);
                impVal = origRenderIMPs[name];
                if (impVal) break;
                cls = class_getSuperclass(cls);
            }
        }
        if (impVal) {
            RenderSampleBufferIMP orig = (RenderSampleBufferIMP)[impVal pointerValue];
            orig(self, _cmd, sampleBuffer, input);
        }
    }
    
    // Update status
    [config updateStatus:@{
        @"state": @"active",
        @"message": @"Prepared virtual frames are being delivered",
        @"hookedClassCount": @(hookedClasses.count),
        @"renderedFrames": @(renderedFrameCount)
    }];
}

#pragma mark - Hook: emitSampleBuffer:

static void hooked_emitSampleBuffer(id self, SEL _cmd, CMSampleBufferRef sampleBuffer) {
    NSString *className = NSStringFromClass([self class]);
    
    VCamConfig *config = [VCamConfig sharedConfig];
    if (!config.injectionEnabled) {
        NSValue *impVal = origEmitIMPs[className];
        if (!impVal) {
            Class cls = [self class];
            while (cls) {
                NSString *name = NSStringFromClass(cls);
                impVal = origEmitIMPs[name];
                if (impVal) break;
                cls = class_getSuperclass(cls);
            }
        }
        if (impVal) {
            EmitSampleBufferIMP orig = (EmitSampleBufferIMP)[impVal pointerValue];
            orig(self, _cmd, sampleBuffer);
        }
        return;
    }
    
    CMSampleBufferRef replacedBuffer = [[VCamRenderer sharedRenderer]
                                         renderReplacementForSampleBuffer:sampleBuffer
                                         purpose:0];
    
    if (replacedBuffer) {
        renderedFrameCount++;
        NSValue *impVal = origEmitIMPs[className];
        if (!impVal) {
            Class cls = [self class];
            while (cls) {
                NSString *name = NSStringFromClass(cls);
                impVal = origEmitIMPs[name];
                if (impVal) break;
                cls = class_getSuperclass(cls);
            }
        }
        if (impVal) {
            EmitSampleBufferIMP orig = (EmitSampleBufferIMP)[impVal pointerValue];
            orig(self, _cmd, replacedBuffer);
        }
        CFRelease(replacedBuffer);
    } else {
        NSValue *impVal = origEmitIMPs[className];
        if (!impVal) {
            Class cls = [self class];
            while (cls) {
                NSString *name = NSStringFromClass(cls);
                impVal = origEmitIMPs[name];
                if (impVal) break;
                cls = class_getSuperclass(cls);
            }
        }
        if (impVal) {
            EmitSampleBufferIMP orig = (EmitSampleBufferIMP)[impVal pointerValue];
            orig(self, _cmd, sampleBuffer);
        }
    }
}

#pragma mark - ABI Check

static BOOL vcamCheckMethodABI(Class cls, SEL sel, const char *expectedArgTypes[], NSUInteger expectedArgCount) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return NO;
    
    unsigned int argCount = method_getNumberOfArguments(m);
    if (argCount != expectedArgCount) return NO;
    
    for (unsigned int i = 0; i < argCount && i < expectedArgCount; i++) {
        if (expectedArgTypes[i] == NULL) continue;
        char *argType = method_copyArgumentType(m, i);
        if (!argType) return NO;
        BOOL match = (strcmp(argType, expectedArgTypes[i]) == 0);
        free(argType);
        if (!match) return NO;
    }
    
    return YES;
}

#pragma mark - Hook Installation

static void vcamHookRenderMethod(Class cls) {
    NSString *className = NSStringFromClass(cls);
    SEL sel = @selector(renderSampleBuffer:forInput:);
    
    // ABI check: (self, _cmd, CMSampleBufferRef, NSInteger)
    const char *expectedArgs[] = { "@", ":", "^{opaqueCMSampleBuffer=}", "q" };
    if (!vcamCheckMethodABI(cls, sel, expectedArgs, 4)) {
        os_log(vcamLog, "skipped %{public}s because its runtime ABI is incompatible", className.UTF8String);
        return;
    }
    
    Method method = class_getInstanceMethod(cls, sel);
    IMP origIMP = method_getImplementation(method);
    origRenderIMPs[className] = [NSValue valueWithPointer:(void *)origIMP];
    
    MSHookMessageEx(cls, sel, (IMP)hooked_renderSampleBuffer_forInput, NULL);
    
    [hookedClasses addObject:className];
    os_log(vcamLog, "installed ABI-checked hook for %{public}s|renderSampleBuffer:forInput:", className.UTF8String);
}

static void vcamHookEmitMethod(Class cls) {
    NSString *className = NSStringFromClass(cls);
    SEL sel = @selector(emitSampleBuffer:);
    
    const char *expectedArgs[] = { "@", ":", "^{opaqueCMSampleBuffer=}" };
    if (!vcamCheckMethodABI(cls, sel, expectedArgs, 3)) {
        os_log(vcamLog, "skipped %{public}s because its runtime ABI is incompatible", className.UTF8String);
        return;
    }
    
    Method method = class_getInstanceMethod(cls, sel);
    IMP origIMP = method_getImplementation(method);
    origEmitIMPs[className] = [NSValue valueWithPointer:(void *)origIMP];
    
    MSHookMessageEx(cls, sel, (IMP)hooked_emitSampleBuffer, NULL);
    
    [hookedClasses addObject:className];
    os_log(vcamLog, "installed ABI-checked hook for %{public}s|emitSampleBuffer:", className.UTF8String);
}

void VCamInstallHooks(void) {
    // Hook known pipeline sink classes
    NSArray *renderClasses = @[
        @"BWImageQueueSinkNode",
        @"BWRemoteQueueSinkNode",
        @"BWPhotoEncoderNode",
        @"BWStillImageSampleBufferSinkNode"
    ];
    
    for (NSString *name in renderClasses) {
        Class cls = objc_getClass(name.UTF8String);
        if (cls) {
            vcamHookRenderMethod(cls);
        }
    }
    
    // Emit-based classes
    NSArray *emitClasses = @[
        @"BWNodeOutput"
    ];
    
    for (NSString *name in emitClasses) {
        Class cls = objc_getClass(name.UTF8String);
        if (cls) {
            vcamHookEmitMethod(cls);
        }
    }
}

void VCamInstallPreviewHooks(void) {
    // iOS 16+ dynamically discovers BWPreviewSinkNode subclasses
    Class previewBase = objc_getClass("BWPreviewSinkNode");
    if (!previewBase) return;
    
    unsigned int classCount = 0;
    Class *allClasses = objc_copyClassList(&classCount);
    
    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = allClasses[i];
        Class superCls = class_getSuperclass(cls);
        
        // Check if it's a subclass of BWPreviewSinkNode
        while (superCls) {
            if (superCls == previewBase) {
                NSString *name = NSStringFromClass(cls);
                if (![hookedClasses containsObject:name]) {
                    // Try emitSampleBuffer: first
                    if (class_getInstanceMethod(cls, @selector(emitSampleBuffer:))) {
                        vcamHookEmitMethod(cls);
                        os_log(vcamLog, "Hooked iOS 16 preview subclass %{public}s", name.UTF8String);
                    }
                }
                break;
            }
            superCls = class_getSuperclass(superCls);
        }
    }
    
    free(allClasses);
    
    // Also hook BWPreviewSinkNode itself if it has emitSampleBuffer:
    if (class_getInstanceMethod(previewBase, @selector(emitSampleBuffer:))) {
        NSString *name = NSStringFromClass(previewBase);
        if (![hookedClasses containsObject:name]) {
            vcamHookEmitMethod(previewBase);
        }
    }
}

#pragma mark - Constructor

__attribute__((constructor))
static void vcamCameraInit(void) {
    vcamLog = os_log_create("com.vcam.mch", "hook");
    hookedClasses = [NSMutableSet new];
    origRenderIMPs = [NSMutableDictionary new];
    origEmitIMPs = [NSMutableDictionary new];
    
    const char *processName = getprogname();
    os_log(vcamLog, "starting in process %{public}s", processName);
    
    // Initialize config
    [VCamConfig sharedConfig];
    
    // Install hooks
    VCamInstallHooks();
    VCamInstallPreviewHooks();
    
    // Update status
    [[VCamConfig sharedConfig] updateStatus:@{
        @"state": @"waiting",
        @"message": @"Waiting for camera pipeline",
        @"process": [NSString stringWithUTF8String:processName],
        @"hookedClassCount": @(hookedClasses.count)
    }];
    
    os_log(vcamLog, "Vcam_Mch camera hook ready — %lu classes hooked", (unsigned long)hookedClasses.count);
}
