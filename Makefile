GO_EASY_ON_ME = 1

include /home/squid/theos/makefiles/common.mk

TWEAK_NAME = PinPrefs
PinPrefs_FILES = Tweak.xm
PinPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
