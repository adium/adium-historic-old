@class CSWebTabViewItem;

@interface CSWebViewController : NSObject {
	IBOutlet WebView				*webView_main;
	IBOutlet NSTextField			*textField_location;
	IBOutlet NSSearchField			*searchField_google;
	IBOutlet NSView					*view_main;
	IBOutlet NSProgressIndicator	*progress;
	IBOutlet NSTextField			*textField_status;
	id								delegate;
}

+ (CSWebViewController *)webViewController;
- (IBAction)searchGoogle:(id)sender;
- (void)setDelegate:(id)inDelegate;
- (id)delegate;
- (NSView *)view;
- (NSURL *)URL;
- (NSString *)title;
- (void)loadURL:(NSURL *)inURL;

@end
