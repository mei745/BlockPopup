ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:14.0

THEOS_PACKAGE_DIR_NAME = debs
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BlockPopup
BlockPopup_FILES = Tweak.xm
BlockPopup_FRAMEWORKS = UIKit
BlockPopup_LDFLAGS = -dynamiclib -install_name @rpath/$(TWEAK_NAME).dylib

include $(THEOS_MAKE_PATH)/tweak.mk

# 重命名自定义目标，避免和Theos内置的package冲突
build-dylib: clean all
	@echo "生成独立动态库：.theos/obj/debug/$(TWEAK_NAME).dylib"
	cp .theos/obj/debug/$(TWEAK_NAME).dylib ./$(TWEAK_NAME).dylib

# 重命名为build-deb，替代原来的package
build-deb: build-dylib
	@echo "生成deb包：$(TWEAK_NAME).deb"
	mkdir -p .theos/deb/DEBIAN .theos/deb/Library/MobileSubstrate/DynamicLibraries
	cp $(TWEAK_NAME).dylib .theos/deb/Library/MobileSubstrate/DynamicLibraries/
	cp $(TWEAK_NAME).plist .theos/deb/Library/MobileSubstrate/DynamicLibraries/
	echo -e "Package: com.temp.$(TWEAK_NAME)\nVersion: 1.0.0\nArchitecture: iphoneos-arm" > .theos/deb/DEBIAN/control
	dpkg-deb -b .theos/deb $(TWEAK_NAME).deb

# 重命名为extract-lib，关联新目标
extract-lib: build-deb
	@echo "提取动态库"
	dpkg-deb -x $(TWEAK_NAME).deb ./deb-extract
	cp ./deb-extract/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).dylib ./
	rm -rf ./deb-extract
