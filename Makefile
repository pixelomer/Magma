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