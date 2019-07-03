PATH += :./fakebins
export PATH

# Options
SKIP_CODESIGNING ?= 0

# Theos configuration
TARGET = ::9.0
include $(THEOS)/makefiles/common.mk
APPLICATION_NAME = Magma
Magma_FILES = $(wildcard */*.m)
Magma_CFLAGS = -fobjc-arc -I. -include Magma/macros.h -Wno-parentheses -Wno-deprecated-declarations
ifeq ($(I_MODIFIED_EVERYTHING),1)
Magma_CFLAGS += -ferror-limit=0
endif
Magma_LDFLAGS = -L./lib -lbz2
include $(THEOS_MAKE_PATH)/application.mk

ifeq ($(SKIP_CODESIGNING),1)
codesign: prepare-application
	@true
else
codesign: prepare-application
	@echo -e "\033[0;31m> \033[3;1;37mCodesigning application $(APPLICATION_NAME)…\033[0m"
	@cp Entitlements.xml "$(THEOS_OBJ_DIR)/Entitlements.xml"
	@sed -i.bak 's/{TEAM_ID}/$(shell ./private.sh team-id)/g' "$(THEOS_OBJ_DIR)/Entitlements.xml"
	@sed -i.bak 's/{BUNDLE_ID}/$(shell ./private.sh bundle-id)/g' "$(THEOS_OBJ_DIR)/Entitlements.xml"
	@codesign --force --sign "$(shell ./private.sh signature)" --timestamp=none --entitlements "Entitlements.xml" --identifier "com.pixelomer.Magma" "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app"
	@codesign --verify "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app"
endif

prepare-application: $(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app
	@sed -i.bak 's/{BUNDLE_ID}/$(shell ./private.sh bundle-id)/g' "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app/Info.plist"
	@rm -f "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app/Info.plist.bak"

all:: codesign
	@echo -e "\033[0;31m> \033[3;1;37mBuilding an ipa for application $(APPLICATION_NAME)…\033[0m"
	@mkdir "$(THEOS_OBJ_DIR)/Payload"
	@cp -r "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app" "$(THEOS_OBJ_DIR)/Payload/"
	@pushd "$(THEOS_OBJ_DIR)" 2&> /dev/null; \
		zip -qr "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).ipa" "Payload"; \
		popd 2&> /dev/null;
	@rm -rf "$(THEOS_OBJ_DIR)/Payload/"

deploy: all
	@type -p ios-deploy 2&> /dev/null || { echo -e "\033[0;31mError: \033[0mios-deploy is required to deploy the application to an iOS device."; exit 1; }
	ios-deploy $(DEPLOY_ARGS) -W -b "$(THEOS_OBJ_DIR)/$(APPLICATION_NAME).app" > /dev/null