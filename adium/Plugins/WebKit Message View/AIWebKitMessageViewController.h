
#import <WebKit/WebKit.h>


@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	WebView		*webView;

    NSMutableString             *timeStampFormat;
    NSDateFormatter		*timeStampFormatter;
	
	AIContentObject	*previousContent;
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat;

@end
