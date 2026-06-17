TARGET := iphone:clang:latest:7.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = vone

vone_FILES = Tweak.xm
# 【关键修改】添加 -I. 表示在当前目录寻找头文件，这样 #import "headers/xxx.h" 才能生效
vone_CFLAGS = -fobjc-arc -I.
vone_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
    install.exec "killall -9 WeChat"
