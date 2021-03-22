PLATFORM               ?= PLATFORM_ANDROID
RAYLIB_PATH            ?= C:\raylib\raylib


ANDROID_ARCH           ?= ARM64
ANDROID_API_VERSION     = 29


ANDROID_NDK = C:/android-ndk
ANDROID_TOOLCHAIN = $(ANDROID_NDK)/toolchains/llvm/prebuilt/windows-x86_64


ANDROID_ARCH_NAME = arm64-v8a

JAVA_HOME              ?= C:/open-jdk
ANDROID_HOME            = C:/android-sdk
ANDROID_TOOLCHAIN       = $(ANDROID_NDK)/toolchains/llvm/prebuilt/windows-x86_64
ANDROID_BUILD_TOOLS     = $(ANDROID_HOME)/build-tools/29.0.3
ANDROID_PLATFORM_TOOLS  = $(ANDROID_HOME)/platform-tools

PROJECT_NAME           ?= androidsensor
PROJECT_LIBRARY_NAME   ?= main
PROJECT_BUILD_PATH     ?= ramware.$(PROJECT_NAME)
PROJECT_RESOURCES_PATH ?= resources
PROJECT_SOURCE_FILES   ?= main.c

PROJECT_SOURCE_DIRS = $(sort $(dir $(PROJECT_SOURCE_FILES)))

APP_LABEL_NAME ?= Gyro
APP_COMPANY_NAME ?= ramware
APP_PRODUCT_NAME ?= andsensor
APP_VERSION_CODE ?= 1
APP_VERSION_NAME ?= 1.0
APP_ICON_LDPI ?= $(RAYLIB_PATH)\logo\raylib_36x36.png
APP_ICON_MDPI ?= $(RAYLIB_PATH)\logo\raylib_48x48.png
APP_ICON_HDPI ?= $(RAYLIB_PATH)\logo\raylib_72x72.png
APP_SCREEN_ORIENTATION ?= portrait
APP_KEYSTORE_PASS ?= raylib

RAYLIB_LIBTYPE ?= STATIC

RAYLIB_LIB_PATH = $(RAYLIB_PATH)\src

ifeq ($(RAYLIB_LIBTYPE),SHARED)
    PROJECT_SHARED_LIBS = lib/$(ANDROID_ARCH_NAME)/libraylib.so 
endif


CC = $(ANDROID_TOOLCHAIN)/bin/aarch64-linux-android$(ANDROID_API_VERSION)-clang
AR = $(ANDROID_TOOLCHAIN)/bin/aarch64-linux-android-ar

CFLAGS = -std=c99 -target aarch64 -mfix-cortex-a53-835769

CFLAGS += -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC
CFLAGS += -Wall -Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes
CFLAGS += -DANDROID -DPLATFORM_ANDROID -D__ANDROID_API__=$(ANDROID_API_VERSION)

INCLUDE_PATHS = -I. -I$(RAYLIB_PATH)/src -I$(RAYLIB_PATH)/src/external/android/native_app_glue

LDFLAGS = -Wl,-soname,lib$(PROJECT_LIBRARY_NAME).so -Wl,--exclude-libs,libatomic.a 
LDFLAGS += -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings 
LDFLAGS += -u ANativeActivity_onCreate
LDFLAGS += -L. -L$(PROJECT_BUILD_PATH)/obj -L$(PROJECT_BUILD_PATH)/lib/$(ANDROID_ARCH_NAME) -L$(ANDROID_TOOLCHAIN)\sysroot\usr\lib

LDLIBS = -lm -lc -lraylib -llog -landroid -lEGL -lGLESv2 -lOpenSLES -ldl

OBJS = $(patsubst %.c, $(PROJECT_BUILD_PATH)/obj/%.o, $(PROJECT_SOURCE_FILES))

all: create_temp_project_dirs \
     copy_project_required_libs \
     copy_project_resources \
     generate_loader_script \
     generate_android_manifest \
     generate_apk_keystore \
     config_project_package \
     compile_project_code \
     compile_project_class \
     compile_project_class_dex \
     create_project_apk_package \
     sign_project_apk_package \
     zipalign_project_apk_package

create_temp_project_dirs:
	@echo creating directories
	@if not exist $(PROJECT_BUILD_PATH) mkdir $(PROJECT_BUILD_PATH) 
	@if not exist $(PROJECT_BUILD_PATH)\obj mkdir $(PROJECT_BUILD_PATH)\obj
	@if not exist $(PROJECT_BUILD_PATH)\src mkdir $(PROJECT_BUILD_PATH)\src
	@if not exist $(PROJECT_BUILD_PATH)\src\com mkdir $(PROJECT_BUILD_PATH)\src\com
	@if not exist $(PROJECT_BUILD_PATH)\src\com\$(APP_COMPANY_NAME) mkdir $(PROJECT_BUILD_PATH)\src\com\$(APP_COMPANY_NAME)
	@if not exist $(PROJECT_BUILD_PATH)\src\com\$(APP_COMPANY_NAME)\$(APP_PRODUCT_NAME) mkdir $(PROJECT_BUILD_PATH)\src\com\$(APP_COMPANY_NAME)\$(APP_PRODUCT_NAME)
	@if not exist $(PROJECT_BUILD_PATH)\lib mkdir $(PROJECT_BUILD_PATH)\lib
	@if not exist $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME) mkdir $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME)
	@if not exist $(PROJECT_BUILD_PATH)\bin mkdir $(PROJECT_BUILD_PATH)\bin
	@if not exist $(PROJECT_BUILD_PATH)\res mkdir $(PROJECT_BUILD_PATH)\res
	@if not exist $(PROJECT_BUILD_PATH)\res\drawable-ldpi mkdir $(PROJECT_BUILD_PATH)\res\drawable-ldpi
	@if not exist $(PROJECT_BUILD_PATH)\res\drawable-mdpi mkdir $(PROJECT_BUILD_PATH)\res\drawable-mdpi
	@if not exist $(PROJECT_BUILD_PATH)\res\drawable-hdpi mkdir $(PROJECT_BUILD_PATH)\res\drawable-hdpi
	@if not exist $(PROJECT_BUILD_PATH)\res\values mkdir $(PROJECT_BUILD_PATH)\res\values
	@if not exist $(PROJECT_BUILD_PATH)\assets mkdir $(PROJECT_BUILD_PATH)\assets
	@if not exist $(PROJECT_BUILD_PATH)\assets\$(PROJECT_RESOURCES_PATH) mkdir $(PROJECT_BUILD_PATH)\assets\$(PROJECT_RESOURCES_PATH)
	@if not exist $(PROJECT_BUILD_PATH)\obj\screens mkdir $(PROJECT_BUILD_PATH)\obj\screens
	@$(foreach dir, $(PROJECT_SOURCE_DIRS), $(call create_dir, $(dir)))

define create_dir
    if not exist $(PROJECT_BUILD_PATH)\obj\$(1) mkdir $(PROJECT_BUILD_PATH)\obj\$(1)
endef
    
copy_project_required_libs:
ifeq ($(RAYLIB_LIBTYPE),SHARED)
	copy /Y $(RAYLIB_LIB_PATH)\libraylib.so $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME)\libraylib.so 
endif
ifeq ($(RAYLIB_LIBTYPE),STATIC)
	copy /Y $(RAYLIB_LIB_PATH)\libraylib.a $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME)\libraylib.a 
endif

copy_project_resources:
	copy $(APP_ICON_LDPI) $(PROJECT_BUILD_PATH)\res\drawable-ldpi\icon.png /Y
	copy $(APP_ICON_MDPI) $(PROJECT_BUILD_PATH)\res\drawable-mdpi\icon.png /Y
	copy $(APP_ICON_HDPI) $(PROJECT_BUILD_PATH)\res\drawable-hdpi\icon.png /Y
	@echo ^<?xml version="1.0" encoding="utf-8"^?^> > $(PROJECT_BUILD_PATH)/res/values/strings.xml
	@echo ^<resources^>^<string name="app_name"^>$(APP_LABEL_NAME)^</string^>^</resources^> >> $(PROJECT_BUILD_PATH)/res/values/strings.xml
	if exist $(PROJECT_RESOURCES_PATH) C:\Windows\System32\xcopy $(PROJECT_RESOURCES_PATH) $(PROJECT_BUILD_PATH)\assets\$(PROJECT_RESOURCES_PATH) /Y /E /F

generate_loader_script:
	@echo package com.$(APP_COMPANY_NAME).$(APP_PRODUCT_NAME); > $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java
	@echo. >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java
	@echo public class NativeLoader extends android.app.NativeActivity { >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java
	@echo     static { >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java
ifeq ($(RAYLIB_LIBTYPE),SHARED)
	@echo         System.loadLibrary("raylib"); >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java
endif
	@echo         System.loadLibrary("$(PROJECT_LIBRARY_NAME)"); >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java 
	@echo     } >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java
	@echo } >> $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java




generate_android_manifest:
	@echo ^<?xml version="1.0" encoding="utf-8"^?^> > $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android" >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo         package="com.$(APP_COMPANY_NAME).$(APP_PRODUCT_NAME)"  >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo         android:versionCode="$(APP_VERSION_CODE)" android:versionName="$(APP_VERSION_NAME)" ^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo     ^<uses-sdk android:minSdkVersion="$(ANDROID_API_VERSION)" /^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo     ^<uses-feature android:glEsVersion="0x00020000" android:required="true" /^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo     ^<uses-permission android:name="android.Permissionission.INTERNET" /^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo     ^<application android:allowBackup="false" android:label="@string/app_name" android:icon="@drawable/icon" ^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo         ^<activity android:name="com.$(APP_COMPANY_NAME).$(APP_PRODUCT_NAME).NativeLoader" >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             android:theme="@android:style/Theme.NoTitleBar.Fullscreen" >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             android:configChanges="orientation|keyboardHidden|screenSize" >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             android:screenOrientation="$(APP_SCREEN_ORIENTATION)" android:launchMode="singleTask" >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             android:clearTaskOnLaunch="true"^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             ^<meta-data android:name="android.app.lib_name" android:value="$(PROJECT_LIBRARY_NAME)" /^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             ^<intent-filter^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo                 ^<action android:name="android.intent.action.MAIN" /^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo                 ^<category android:name="android.intent.category.LAUNCHER" /^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo             ^</intent-filter^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo         ^</activity^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo     ^</application^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml
	@echo ^</manifest^> >> $(PROJECT_BUILD_PATH)/AndroidManifest.xml

generate_apk_keystore: 
	if not exist $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore $(JAVA_HOME)/bin/keytool -genkeypair -validity 10000 -dname "CN=$(APP_COMPANY_NAME),O=Android,C=ES" -keystore $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore -storepass $(APP_KEYSTORE_PASS) -keypass $(APP_KEYSTORE_PASS) -alias $(PROJECT_NAME)Key -keyalg RSA

config_project_package:
	$(ANDROID_BUILD_TOOLS)/aapt package -f -m -S $(PROJECT_BUILD_PATH)/res -J $(PROJECT_BUILD_PATH)/src -M $(PROJECT_BUILD_PATH)/AndroidManifest.xml -I $(ANDROID_HOME)/platforms/android-$(ANDROID_API_VERSION)/android.jar

compile_native_app_glue:
	$(CC) -c $(RAYLIB_PATH)/src/external/android/native_app_glue/android_native_app_glue.c -o $(PROJECT_BUILD_PATH)/obj/native_app_glue.o $(CFLAGS)
	$(AR) rcs $(PROJECT_BUILD_PATH)/obj/libnative_app_glue.a $(PROJECT_BUILD_PATH)/obj/native_app_glue.o

compile_project_code: $(OBJS)
	$(CC) -o $(PROJECT_BUILD_PATH)/lib/$(ANDROID_ARCH_NAME)/lib$(PROJECT_LIBRARY_NAME).so $(OBJS) -shared $(INCLUDE_PATHS) $(LDFLAGS) $(LDLIBS)

$(PROJECT_BUILD_PATH)/obj/%.o:%.c
	$(CC) -c $^ -o $@ $(INCLUDE_PATHS) $(CFLAGS) --sysroot=$(ANDROID_TOOLCHAIN)/sysroot 

compile_project_class:
	$(JAVA_HOME)/bin/javac -source 1.7 -target 1.7 -d $(PROJECT_BUILD_PATH)/obj -bootclasspath $(JAVA_HOME)/jre/lib/rt.jar -classpath $(ANDROID_HOME)/platforms/android-$(ANDROID_API_VERSION)/android.jar;$(PROJECT_BUILD_PATH)/obj -sourcepath $(PROJECT_BUILD_PATH)/src $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/R.java $(PROJECT_BUILD_PATH)/src/com/$(APP_COMPANY_NAME)/$(APP_PRODUCT_NAME)/NativeLoader.java

compile_project_class_dex:
	$(ANDROID_BUILD_TOOLS)/dx  --dex --output=$(PROJECT_BUILD_PATH)/bin/classes.dex $(PROJECT_BUILD_PATH)/obj

create_project_apk_package:
	$(ANDROID_BUILD_TOOLS)/aapt package -f -M $(PROJECT_BUILD_PATH)/AndroidManifest.xml -S $(PROJECT_BUILD_PATH)/res -A $(PROJECT_BUILD_PATH)/assets -I $(ANDROID_HOME)/platforms/android-$(ANDROID_API_VERSION)/android.jar -F $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).unsigned.apk $(PROJECT_BUILD_PATH)/bin
	cd $(PROJECT_BUILD_PATH) && $(ANDROID_BUILD_TOOLS)/aapt add bin/$(PROJECT_NAME).unsigned.apk lib/$(ANDROID_ARCH_NAME)/lib$(PROJECT_LIBRARY_NAME).so $(PROJECT_SHARED_LIBS)

sign_project_apk_package:
	$(JAVA_HOME)/bin/jarsigner -keystore $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore -storepass $(APP_KEYSTORE_PASS) -keypass $(APP_KEYSTORE_PASS) -signedjar $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).signed.apk $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).unsigned.apk $(PROJECT_NAME)Key

zipalign_project_apk_package:
	$(ANDROID_BUILD_TOOLS)/zipalign -f 4 $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).signed.apk $(PROJECT_NAME).apk

install:
	$(ANDROID_PLATFORM_TOOLS)/adb install $(PROJECT_NAME).apk

uninstall: 
	$(ANDROID_PLATFORM_TOOLS)/adb uninstall com.$(APP_COMPANY_NAME).$(APP_PRODUCT_NAME)

run: 
	$(ANDROID_PLATFORM_TOOLS)/adb shell am start -n  com.$(APP_COMPANY_NAME).$(APP_PRODUCT_NAME)/com.$(APP_COMPANY_NAME).$(APP_PRODUCT_NAME).NativeLoader

check_device_abi:
	$(ANDROID_PLATFORM_TOOLS)/adb shell getprop ro.product.cpu.abi

logcat:
	$(ANDROID_PLATFORM_TOOLS)/adb logcat -c
	$(ANDROID_PLATFORM_TOOLS)/adb logcat raylib:V *:S

deploy:
	$(ANDROID_PLATFORM_TOOLS)/adb install $(PROJECT_NAME).apk
	$(ANDROID_PLATFORM_TOOLS)/adb logcat -c
	$(ANDROID_PLATFORM_TOOLS)/adb logcat raylib:V *:S


clean:
	del $(PROJECT_BUILD_PATH)\* /f /s /q
	rmdir $(PROJECT_BUILD_PATH) /s /q
	@echo Cleaning done






