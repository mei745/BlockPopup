ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:14.0

THEOS_PACKAGE_DIR_NAME = debs
# 用绝对路径引入Theos文件
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BlockPopup
BlockPopup_FILES = Tweak.xm
BlockPopup_FRAMEWORKS = UIKit
BlockPopup_LDFLAGS = -dynamiclib -install_name @rpath/$(TWEAK_NAME).dylib

# 同样用绝对路径引入tweak.mk
include $(THEOS)/makefiles/tweak.mk

build-dylib: clean all
	@echo "生成动态库"
	cp .theos/obj/debug/$(TWEAK_NAME).dylib ./$(TWEAK_NAME).dylib

build-deb: build-dylib
	@echo "生成deb"
	mkdir -p .theos/deb/DEBIAN .theos/deb/Library/MobileSubstrate/DynamicLibraries
	cp $(TWEAK_NAME).dylib .theos/deb/Library/MobileSubstrate/DynamicLibraries/
	cp $(TWEAK_NAME).plist .theos/deb/Library/MobileSubstrate/DynamicLibraries/
	echo -e "Package: com.temp.$(TWEAK_NAME)\nVersion: 1.0.0\nArchitecture: iphoneos-arm" > .theos/deb/DEBIAN/control
	dpkg-deb -b .theos/deb $(TWEAK_NAME).deb

extract-lib: build-deb
	@echo "提取库"
	dpkg-deb -x $(TWEAK_NAME).deb ./deb-extract
	cp ./deb-extract/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).dylib ./
	rm -rf ./deb-extract
