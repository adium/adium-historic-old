
#import <WebKit/WebKit.h>


@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	WebView		*webView;
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat;

@end
