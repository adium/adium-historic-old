
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
	BOOL						shouldRefreshContent;
	
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
	NSString					*backgroundOriginalPath;
	NSColor						*backgroundColor;
	
	NSDateFormatter				*timeStampFormatter;
	NameFormat					nameFormat;
	BOOL						allowColors;
	BOOL						showUserIcons;
	BOOL						allowBackgrounds;
	BOOL						useCustomNameFormat;
	BOOL						combineConsecutive;
	BOOL						allowTextBackgrounds;
	int							styleVersion;	
	NSImage						*imageMask;
	NSMutableArray				*objectsWithUserIconsArray;
	AIImageBackgroundStyle		imageBackgroundStyle;
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)forceReload;

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
@end
