export SIMJECT ?= 0
export ROOTLESS ?= 0
export NO_DEPENDENCIES ?= 0
export DEBUG_LOGGING ?= 0
export NO_LIBCOLORPICKER ?= 0

ifeq ($(ROOTLESS),1)
export NO_DEPENDENCIES = 1
endif

ifeq ($(SIMJECT),1)
export TARGET = simulator:clang:14.5:8.0
export ARCHS = x86_64 i386
else
export TARGET = iphone:clang:14.5:8.0
export ARCHS = armv7 armv7s arm64 arm64e
endif

ifeq ($(NO_DEPENDENCIES),1)
export NO_LIBCOLORPICKER = 1
endif

export INCLUDES = $(THEOS_PROJECT_DIR)/Shared

include $(THEOS)/makefiles/common.mk

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS = MobileSafari WebContent SpringBoard Preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 MobileSafari"
