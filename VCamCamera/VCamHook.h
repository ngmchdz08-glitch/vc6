#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <objc/runtime.h>
#import <os/log.h>

@class VCamRenderer;

// Forward declarations for private Apple classes
@interface NSObject (BWPipelineNode)
- (void)renderSampleBuffer:(CMSampleBufferRef)sampleBuffer forInput:(NSInteger)input;
- (void)emitSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

/// Installs hooks on known BW* camera pipeline classes in mediaserverd.
void VCamInstallHooks(void);

/// Dynamically discovers and hooks iOS 16+ preview subclasses.
void VCamInstallPreviewHooks(void);
