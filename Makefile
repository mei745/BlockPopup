# 指定 iOS 版本和 CPU 架构
# 修改说明：去掉了中间的 "14.5"，让 Theos 自动使用最新的 SDK
TARGET := iphone:clang:12.0
ARCHS := arm64 x86_64

# 指定 Theos 的安装路径
THEOS := /opt/theos

# 定义要注入的进程
INSTALL_TARGET_PROCESSES = SpringBoard

# 指定要编译的 Tweak 名称
TWEAK_NAME = mei745

# 指定源文件
mei745_FILES = Tweak.xm

# 开启现代 Objective-C 语法支持 (ARC)
mei745_CFLAGS = -fobjc-arc

# 引入 Theos 的主构建规则
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
