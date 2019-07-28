include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = saprefs

saprefs_FILES = SAPRootListController.mm ViewController.m
saprefs_INSTALL_PATH = /Library/PreferenceBundles
saprefs_FRAMEWORKS = UIKit
saprefs_PRIVATE_FRAMEWORKS = Preferences
saprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/saprefs.plist$(ECHO_END)
