# 指定目标平台和架构
TARGET := iphone:clang:latest
ARCHS := arm64 x86_64

# --- 关键修复：忽略过时 API 的报错 ---
# 告诉编译器不要因为使用了旧代码(如 UIAlertView)而报错
THEOS_LDFLAGS += -Wno-deprecated-declarations

# 强制使用旧版 Logos 语法 (%hook)
THEOS_USE_LEAN_LOGOS=1

# 指定要注入的进程
INSTALL_TARGET_PROCESSES = SpringBoard

# 指定 Tweak 名称
TWEAK_NAME = mei745

# 指定源文件
mei745_FILES = Tweak.xm

# 开启 ARC 支持
mei745_CFLAGS = -fobjc-arc

# 引入构建规则
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
