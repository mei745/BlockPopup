# 指定目标平台和架构
TARGET := iphone:clang:latest:13.0
ARCHS := arm64

# 指定 Tweak 名称
TWEAK_NAME = mei745

# 指定要注入的进程
mei745_INSTALL_TARGET_PROCESSES = SpringBoard

# --- 关键修复：合并编译参数 ---
# 必须把 -fobjc-arc 和 -Wno-deprecated-declarations 写在同一行
# 否则后面的会覆盖前面的，导致修复失效
mei745_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

# 指定源文件
mei745_FILES = Tweak.xm

# 引入构建规则
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
