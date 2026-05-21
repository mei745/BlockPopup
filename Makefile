# 指定 iOS 版本和 CPU 架构
TARGET := iphone:clang:latest
ARCHS := arm64 x86_64

# 指定 Theos 的安装路径 (CI 环境中通常位于 /opt/theos)
THEOS := /opt/theos

# 定义要注入的进程
INSTALL_TARGET_PROCESSES = SpringBoard

# 指定要编译的 Tweak 名称
TWEAK_NAME = mei745

# --- 关键修改：明确指定源文件和类型 ---
# 告诉 Theos 使用 Logos 处理 .xm 文件
mei745_FILES = Tweak.xm
mei745_TYPE = application

# 开启现代 Objective-C 语法支持 (ARC)
mei745_CFLAGS = -fobjc-arc

# 引入 Theos 的主构建规则
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
