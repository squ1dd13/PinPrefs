ARCHS = armv7 arm64
TARGET = iphone:clang: 9.3:7.0
GO_EASY_ON_ME = 1
THEOS_DEVICE_IP = 192.168.1.139

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PinPrefs
PinPrefs_FILES = Tweak.xm
PinPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
