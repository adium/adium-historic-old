
#import <WebKit/WebKit.h>
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebView.h"

@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	ESWebView			*webView;
	
	BOOL				webViewIsReady;
	
    NSMutableString		*timeStampFormat;
    NSDateFormatter		*timeStampFormatter;
	NSDateFormatter		*timeStampFormatterMinutesSeconds;
	
	AIContentObject		*previousContent;
	NSMutableArray		*newContent;
	NSTimer				*newContentTimer;
	
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat;

@end
