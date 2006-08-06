.PHONY: all joscarBridge

joscarBridge:
	rm joscar\ Java\ Bridge/build/Release/*.jar || true
	xcodebuild -project joscar\ Java\ Bridge/joscar\ Java\ Bridge.xcodeproj
	cp joscar\ Java\ Bridge/build/Release/*.jar .
	cp joscar\ Java\ Bridge/build/*.jar .
