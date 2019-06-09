include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Magma

Magma_FILES = $(wildcard Magma/*.m)
Magma_FRAMEWORKS = UIKit
Magma_CFLAGS = -fobjc-arc -I.
Magma_CODESIGN_FLAGS = -SMagma/Magma.entitlements

include $(THEOS_MAKE_PATH)/application.mk