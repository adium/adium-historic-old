###########
# What to do before running this script:
# - openUp needs to be installed.
# - Set VERSION and BETA below
# - To enable beta, also edit Source/AIAdium.h, and set BETA_RELEASE to TRUE. Set it to FALSE when doing a final release.
# - Edit the following plist keys in Adium_2.plist
#		- CFBundleGetInfoString
#		- CFBundleShortVersionString
#		- CFBundleVersion
#
# How to run this script:
# - make all
###########

VERSION=1.0b4
BETA=TRUE

###########
# To release!
# First upload to cachefly. If you don't have access and need to do a release, get with Evan or Chris (tick).
# Triggering the version checker once the release is up:
# 1) Build Adium
# 2) Get the number out of the 'buildnum' file in Adium.app/Contents/Resources
# 3) Paste that number into the appropriate place (adium version or adium-beta version, depending on which you're triggering) in the version.plist file in our sf.net ht_docs folder.  You should be able to ftp into shell.sf.net with your sf.net login/pass and then cd to the right directory (/home/groups/a/ad/adium/htdocs)
###########

###########
# No need for changes below this point
###########

SRC_DIR=..
BUILD_DIR=build
ART_DIR=Artwork
ADIUM_DIR=$(BUILD_DIR)/Adium
RELEASE_NAME=AdiumX_$(VERSION)
ifeq ($(BETA),TRUE)
    BUILDSTYLE=Deployment-Debug
else
    BUILDSTYLE=Deployment
endif
BUILDFLAGS="BUILDCONFIGURATION=$(BUILDSTYLE)"
PRODUCT_DIR=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)
ifeq ($(strip $(PRODUCT_DIR)),)
	ADIUM_BUILD_DIR=$(SRC_DIR)/build/$(BUILDSTYLE)
else
	TARGET_BUILD_DIR=$(PRODUCT_DIR)/$(BUILDSTYLE)
	ADIUM_BUILD_DIR=$(TARGET_BUILD_DIR)
endif
PLIST_DIR=`pwd`/../Plists
ADIUM_PLIST=$(PLIST_DIR)/Adium_2
CRASH_REPORTER_PLIST=$(PLIST_DIR)/Adium\ Crash\ Reporter-Info

.PHONY: all update version compile clean release source createfolder diskimage

all: update version compile release

update:
	svn update $(SRC_DIR)

version:
	@# update the plists
	defaults write $(ADIUM_PLIST) CFBundleGetInfoString '$(VERSION), Copyright 2001-2006 The Adium Team'
	defaults write $(ADIUM_PLIST) CFBundleVersion '$(VERSION)'
	defaults write $(ADIUM_PLIST) CFBundleShortVersionString '$(VERSION)'
	defaults write $(CRASH_REPORTER_PLIST) CFBundleGetInfoString '$(VERSION), Copyright 2001-2006 The Adium Team'
	defaults write $(CRASH_REPORTER_PLIST) CFBundleVersion '$(VERSION)'
	defaults write $(CRASH_REPORTER_PLIST) CFBundleShortVersionString '$(VERSION)'
	plutil -convert xml1 $(ADIUM_PLIST).plist
	plutil -convert xml1 $(CRASH_REPORTER_PLIST).plist

compile:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)

testcompile:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)

clean:
	rm -rf $(BUILD_DIR)

release: createfolder diskimage

createfolder:
	@# clean build directory
	rm -rf $(BUILD_DIR)
	mkdir $(BUILD_DIR)

	mkdir $(ADIUM_DIR)
	
	@# copy the app
	cp -R $(ADIUM_BUILD_DIR)/Adium.app $(ADIUM_DIR)

	@# copy the text files
	cp $(SRC_DIR)/Changes.txt $(ADIUM_DIR)
	cp $(SRC_DIR)/License.txt $(ADIUM_DIR)
	
	@# symlink /Applications
	ln -s /Applications $(ADIUM_DIR)/Applications

	@# delete svn  and backup files
	find $(BUILD_DIR) -name ".svn" -type d -exec rm -rf {} \; -prune
	find $(BUILD_DIR) \( -name "*~" -or -name .DS_Store \) -type f -delete
	
	@# delete unneeded nib files for non-beta builds
ifeq ($(BETA),FALSE)
	find $(BUILD_DIR) \( -name classes.nib -or -name info.nib \) -type f -delete
endif
	
diskimage:
	rm "$(BUILD_DIR)/$(RELEASE_NAME).dmg" || true
	@# make Adium disk image
	mkdir -p $(ADIUM_DIR)/.background
	cp $(ART_DIR)/dmgBackground.png $(ADIUM_DIR)/.background

	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_NAME).dmg $(ADIUM_DIR) "Adium X $(VERSION)" dmg_adium.scpt
	
	@echo Build finished
