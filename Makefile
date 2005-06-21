BUILDSTYLE?=Development

.PHONY: adium AIUtilities SQLLogger install clean

adium:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDSTYLE) build

AIUtilities:
	xcodebuild -project AIUtilities.framework.xcodeproj -configuration $(BUILDSTYLE) build

SQLLogger:
	xcodebuild -project Adium.xcodeproj -configuration $(BUILDSTYLE) -target "SQL Logger" build
	cp -R "build/SQL Logger.adiumPlugin" ~/Library/Application\ Support/Adium\ 2.0/Plugins/

install:
	cp -R build/Adium.app ~/Applications/
	cp -R build/AIUtilities.framework ~/Library/Frameworks/
clean:
	rm -r build
