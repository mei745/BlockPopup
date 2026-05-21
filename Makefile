# 指定目标平台和架构
# 使用 latest 自动适配最新的 SDK 版本
TARGET := iphone:clang:latest
ARCHS := arm64 x86_64

# --- 关键修复：强制使用旧版 Logos 语法 (%hook) ---
# 因为你的 Tweak.xm 使用的是旧语法，而新版 Theos 默认使用新语法
THEOS_USE_LEAN_LOGOS=1

# 指定要注入的进程
INSTALL_TARGET_PROCESSES = SpringBoard

# 指定 Tweak 名称 (需与 control 文件中的 Package 一致)
TWEAK_NAME = mei745

# 指定源文件
mei745_FILES = Tweak.xm

# 开启 ARC 支持
mei745_CFLAGS = -fobjc-arc

# 引入构建规则
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
