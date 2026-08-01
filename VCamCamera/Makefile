TWEAK_NAME = VCamCamera

VCamCamera_FILES = VCamHook.m VCamRenderer.m VCamVideoReader.m VCamLANStream.m VCamConfig.m
VCamCamera_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
VCamCamera_FRAMEWORKS = Foundation CoreFoundation AVFoundation CoreImage CoreVideo CoreMedia VideoToolbox CoreGraphics ImageIO Vision
VCamCamera_PRIVATE_FRAMEWORKS =
VCamCamera_LIBRARIES =

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
