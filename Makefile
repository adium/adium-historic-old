BUILDSTYLE?=Development

.PHONY: adium AIUtilities SQLLogger install clean

adium:
	xcodebuild -project Adium.xcode -buildstyle $(BUILDSTYLE) build

AIUtilities:
	xcodebuild -project AIUtilities.framework.xcode -buildstyle $(BUILDSTYLE) build

SQLLogger:
	xcodebuild -project Adium.xcode -buildstyle $(BUILDSTYLE) -target "SQL Logger" build
	cp -r "build/SQL Logger.adiumPlugin" "build/Adium.app/Contents/Plugins"; 

install:
	cp -R build/Adium.app ~/Applications/
	cp -R build/AIUtilities.framework ~/Library/Frameworks/
clean:
	rm -r build
