@class CSWebViewController;

@interface CSWebTabViewItem : NSTabViewItem {
	CSWebViewController 	*webView;
}

+ (CSWebTabViewItem *)webTabWithView:(CSWebViewController *)inWebView;
- (void)makeActive:(id)sender;
- (void)close:(id)sender;
- (NSString *)labelString;
- (CSWebViewController *)webViewController;
- (void)tabViewItemWasSelected;
- (void)titleHasChanged;

@end
