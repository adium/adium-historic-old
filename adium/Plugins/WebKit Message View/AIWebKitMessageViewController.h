
#import <WebKit/WebKit.h>


@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	WebView				*webView;
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
