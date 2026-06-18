# 指定目标平台：iOS, clang编译器, 最新SDK, 最低支持iOS 7.0
TARGET := iphone:clang:latest:7.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = vone

vone_FILES = Tweak.xm
vone_CFLAGS = -fobjc-arc -I.
vone_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# 安装后自动重启微信
after-install::
	install.exec "killall -9 WeChat"
