#import "CSWebViewController.h"
#import "CSWebTabViewItem.h"

#define WEB_VIEW_NIB @"WebAdiumView"

@implementation CSWebViewController

+(CSWebViewController *)webViewController
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:WEB_VIEW_NIB owner:self];
	}
	return self;
}

- (void)dealloc
{
	if (delegate) [delegate release];
	[super dealloc];
}

- (IBAction)searchGoogle:(id)sender
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/search?q=%@&ie=UTF-8&oe=UTF-8",[searchField_google stringValue]]];

	[self loadURL:url];
}

- (void)setDelegate:(id)inDelegate
{
	if (delegate) {[delegate release];delegate = nil;}
	delegate = [inDelegate retain];
}
- (id)delegate
{
	return delegate;
}

- (NSView *)view
{
	return view_main;
}

- (NSString *)title
{
	return [[[webView_main mainFrame] dataSource] pageTitle];
}

- (NSURL *)URL
{
	return [[[[webView_main mainFrame] dataSource] request] URL];
}

- (void)loadURL:(NSURL *)inURL
{
	[textField_location setStringValue:[inURL absoluteString]];
	[webView_main takeStringURLFrom:textField_location];
	[progress setDoubleValue:1.0];
	if ([delegate respondsToSelector:@selector(titleHasChanged)]) {
		[delegate titleHasChanged];
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[textField_location setStringValue:[[self URL] absoluteString]];
	if ([delegate respondsToSelector:@selector(titleHasChanged)]) {
		[delegate titleHasChanged];
	}
	[progress setDoubleValue:0.0];
}
- (void)webView:(WebView *)sender setStatusText:(NSString *)text
{
	[textField_status setStringValue:text];
}

@end
