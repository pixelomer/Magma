include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Magma

Magma_FILES = $(wildcard */*.m)
Magma_CFLAGS = -fobjc-arc -I. -include Magma/macros.h -Wno-objc-string-concatenation -Wno-parentheses -Wno-deprecated-declarations
Magma_LDFLAGS = -L./lib -lbz2
Magma_CODESIGN_FLAGS = -SMagma/Magma.entitlements

include $(THEOS_MAKE_PATH)/application.mk