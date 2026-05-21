# 指定 iOS 版本和 CPU 架构 (支持真机 arm64 和模拟器 x86_64)
TARGET := iphone:clang:14.5:12.0
ARCHS := arm64 x86_64

# 指定 Theos 的安装路径 (GitHub Actions 环境中通常位于 /opt/theos)
THEOS := /opt/theos

# 定义包名 (必须与控制文件中的包名一致)
INSTALL_TARGET_PROCESSES = SpringBoard

# 指定要编译的 Tweak 名称
TWEAK_NAME = mei745

# 指定源文件
mei745_FILES = Tweak.xm

# 开启现代 Objective-C 语法支持 (可选，推荐)
mei745_CFLAGS = -fobjc-arc

# 引入 Theos 的主构建规则 (必须放在文件末尾)
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
