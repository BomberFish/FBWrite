TARGET := iphone:clang:latest:11.0
# prevents theos from being overly strict on the stolen xnu source
GO_EASY_ON_ME = 1
# maximize compatibility
ARCHS = arm64

# theos boilerplate
include $(THEOS)/makefiles/common.mk

TOOL_NAME = FBWrite

FBWrite_FILES = main.m
FBWrite_FRAMEWORKS = Foundation IOKit IOSurface CoreGraphics
# you need to patch your sdk for this
FBWrite_EXTRA_FRAMEWORKS = IOMobileFramebuffer
FBWrite_CFLAGS = -fobjc-arc
FBWrite_LDFLAGS = -F./Frameworks
FBWrite_CODESIGN_FLAGS = -Sentitlements.plist
FBWrite_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
