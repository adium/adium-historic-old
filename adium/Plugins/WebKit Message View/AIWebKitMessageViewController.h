
#import <WebKit/WebKit.h>
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebView.h"

@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	ESWebView					*webView;
	NSString					*stylePath;
	NSString					*loadedStyleID;
	NSString					*loadedVariantID;
	AIChat						*chat;
	
	BOOL						webViewIsReady;
	
	AIContentObject				*previousContent;
	NSMutableArray				*newContent;
	NSTimer						*newContentTimer;
	NSTimer						*setStylesheetTimer;
	
	id							plugin;
	
	NSString					*contentInHTML;
	NSString					*nextContentInHTML;
	NSString					*contextInHTML;
	NSString					*nextContextInHTML;
	NSString					*contentOutHTML;
	NSString					*nextContentOutHTML;
	NSString					*contextOutHTML;
	NSString					*nextContextOutHTML;
	NSString					*statusHTML;
	
	NSString					*background;
	NSColor						*backgroundColor;
	
	NSDateFormatter				*timeStampFormatter;
	NameFormat					nameFormat;
	BOOL						allowColors;
	BOOL						showUserIcons;
	BOOL						allowBackgrounds;
	BOOL						useCustomNameFormat;
	BOOL						combineConsecutive;
	int							styleVersion;	
	NSImage						*imageMask;
	NSMutableArray				*objectsWithMaskedUserIconsArray;
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)forceReload;

@end
