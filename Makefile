GO_EASY_ON_ME = 1

include /home/squid/theos/makefiles/common.mk

TWEAK_NAME = StickAround
StickAround_FILES = Tweak.xm
StickAround_PRIVATE_FRAMEWORKS = Preferences
StickAround_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"

SUBPROJECTS += stickaroundprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
