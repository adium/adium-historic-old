PREFIX?=
BUILD_DIR?=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)

ifeq ($(strip $(BUILD_DIR)),)
	BUILD_DIR=build
endif

DEFAULT_BUILDCONFIGURATION=Deployment-Debug

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

CP=ditto --rsrc
RM=rm

.PHONY: all adium clean localizable-strings latest

adium:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) build

SQLLogger:
	    xcodebuild -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION) -target "SQL Logger" build
	    cp -R "build/SQL Logger.adiumPlugin" ~/Library/Application\ Support/Adium\ 2.0/Plugins/

#install:
#	    cp -R build/Adium.app ~/Applications/
#	    cp -R build/AIUtilities.framework ~/Library/Frameworks/

clean:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDCONFIGURATION)  clean


localizable-strings:
	mkdir tmp || true
	mv "Plugins/Gaim Service" tmp
	mv "Plugins/WebKit Message View" tmp
	mv "Plugins/Smack Service" tmp
	genstrings -o Resources/en.lproj -s AILocalizedString Source/*.m Source/*.h Plugins/*/*.h Plugins/*/*.m Plugins/*/*/*.h Plugins/*/*/*.m
	genstrings -o tmp/Gaim\ Service/en.lproj -s AILocalizedString tmp/Gaim\ Service/*.h tmp/Gaim\ Service/*.m
	genstrings -o tmp/WebKit\ Message\ View/en.lproj -s AILocalizedString tmp/WebKit\ Message\ View/*.h tmp/WebKit\ Message\ View/*.m
	genstrings -o Frameworks/AIUtilities\ Framework/Resources/en.lproj -s AILocalizedString Frameworks/AIUtilities\ Framework/Source/*.h Frameworks/AIUtilities\ Framework/Source/*.m
	genstrings -o Frameworks/Adium\ Framework/Resources/en.lproj -s AILocalizedString Frameworks/Adium\ Framework/Source/*.m Frameworks/Adium\ Framework/Source/*.h
	mv "tmp/Gaim Service" Plugins
	mv "tmp/WebKit Message View" Plugins
	rmdir tmp || true

latest:
	svn up
	make adium
