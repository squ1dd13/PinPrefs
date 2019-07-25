include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = StickAroundPrefs

StickAroundPrefs_FILES = SAPRootListController.m
StickAroundPrefs_INSTALL_PATH = /Library/PreferenceBundles
StickAroundPrefs_FRAMEWORKS = UIKit
StickAroundPrefs_PRIVATE_FRAMEWORKS = Preferences
StickAroundPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/StickAroundPrefs.plist$(ECHO_END)
