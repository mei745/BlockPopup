TWEAK_NAME = BlockPopup
BlockPopup_FILES = Tweak.xm
BlockPopup_FRAMEWORKS = UIKit
# 编译为独立动态库（不依赖Theos默认路径）
BlockPopup_LDFLAGS = -dynamiclib -install_name @rpath/$(TWEAK_NAME).dylib

# 目标1：编译动态库（用于后续注入）
build-dylib: clean all
	@echo "生成独立动态库：.theos/obj/debug/$(TWEAK_NAME).dylib"
	# 复制到当前目录方便取用
	cp .theos/obj/debug/$(TWEAK_NAME).dylib ./$(TWEAK_NAME).dylib

# 目标2：生成deb（保留原始结构，方便提取）
package: build-dylib
	@echo "生成deb包（包含动态库）：$(TWEAK_NAME).deb"
	mkdir -p .theos/deb/DEBIAN
	mkdir -p .theos/deb/Library/MobileSubstrate/DynamicLibraries
	cp $(TWEAK_NAME).dylib .theos/deb/Library/MobileSubstrate/DynamicLibraries/
	cp $(TWEAK_NAME).plist .theos/deb/Library/MobileSubstrate/DynamicLibraries/
	# 简化control（仅保留必要信息）
	echo "Package: com.temp.$(TWEAK_NAME)" > .theos/deb/DEBIAN/control
	echo "Version: 1.0.0" >> .theos/deb/DEBIAN/control
	echo "Architecture: iphoneos-arm" >> .theos/deb/DEBIAN/control
	dpkg-deb -b .theos/deb $(TWEAK_NAME).deb

# 目标3：提取deb中的动态库（一键导出）
extract-dylib: package
	@echo "从deb中提取动态库到当前目录"
	dpkg-deb -x $(TWEAK_NAME).deb ./deb-extract
	cp ./deb-extract/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).dylib ./
	rm -rf ./deb-extract

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk