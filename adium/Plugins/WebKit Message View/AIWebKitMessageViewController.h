
#import <WebKit/WebKit.h>
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebView.h"

@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	ESWebView					*webView;
	NSString					*stylePath;
	AIChat						*chat;
	
	BOOL						webViewIsReady;

	AIContentObject				*previousContent;
	NSMutableArray				*newContent;
	NSTimer						*newContentTimer;
	
	AIWebKitMessageViewPlugin   *plugin;
	
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;

@end
