BUILDSTYLE?=Development

.PHONY: adium AIUtilities install clean

adium:
	xcodebuild -project Adium.xcode -buildstyle $(BUILDSTYLE) build

AIUtilities:
	xcodebuild -project AIUtilities.framework.xcode -buildstyle $(BUILDSTYLE) build

install:
	cp -R build/Adium.app ~/Applications/
	cp -R build/AIUtilities.framework ~/Library/Frameworks/
clean:
	rm -r build
