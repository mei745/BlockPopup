# 架构：支持arm64/arm64e（适配新iPhone）
ARCHS = arm64 arm64e
# 编译目标：iOS 16.5 SDK，最低支持iOS 14.0
TARGET = iphone:clang:16.5:14.0
# Deb包输出目录
THEOS_PACKAGE_DIR_NAME = debs

# 引入Theos公共配置
include $(THEOS)/makefiles/common.mk

# Tweak名称
TWEAK_NAME = BlockPopup
# 要编译的文件（你的Tweak代码）
BlockPopup_FILES = Tweak.xm
# 依赖的系统框架（UIKit用于界面操作）
BlockPopup_FRAMEWORKS = UIKit

# 引入Tweak编译规则
include $(THEOS_MAKE_PATH)/tweak.mk

# 安装后重启SpringBoard（可选，用于生效）
after-install::
	install.exec "killall -9 SpringBoard"
