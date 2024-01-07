TARGET := iphone:clang:latest:11.0
# prevents theos from being overly strict on the stolen xnu source
GO_EASY_ON_ME = 1
# maximize compatibility
ARCHS = arm64

# theos boilerplate
include $(THEOS)/makefiles/common.mk

TOOL_NAME = FBWriteImage

FBWriteImage_FILES = main.m
FBWriteImage_FRAMEWORKS = Foundation IOKit IOSurface CoreGraphics
FBWriteImage_PRIVATE_FRAMEWORKS = IOSurface
FBWriteImage_EXTRA_FRAMEWORKS = IOMobileFramebuffer
FBWriteImage_CFLAGS = -fobjc-arc
FBWriteImage_LDFLAGS = -F./Frameworks
FBWriteImage_CODESIGN_FLAGS = -Sentitlements.plist
FBWriteImage_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
