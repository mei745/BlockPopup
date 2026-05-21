ARCHS = arm64 arm64e
TARGET = iphone:latest:17.0  # 与 build.yml 中的 SDKVERSION 一致

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YourTweakName

YourTweakName_FILES = Tweak.x
YourTweakName_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
