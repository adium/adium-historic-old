//
//  AIWebKitMessageViewController.m
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 27 2004.
//

#import "AIWebKitMessageViewController.h"


@interface AIWebKitMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
@end

@implementation AIWebKitMessageViewController

//Create a new message view
+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat
{
    return([[[self alloc] initForChat:inChat] autorelease]);
}

//Init
- (id)initForChat:(AIChat *)inChat
{
    //init
    [super init];
    
	//Observe content
	[[adium notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:inChat];

	//Create our webview
	webView = [[WebView alloc] initWithFrame:NSMakeRect(0,0,100,100) //Arbitrary frame
								   frameName:nil
								   groupName:nil];
//	[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
								  
	//Set it up with the javascript appender template
	NSString	*template = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"html"]];
	[[webView mainFrame] loadHTMLString:template baseURL:nil];

	
    return(self);
}

- (NSView *)messageView
{
	return(webView);
}

- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject		*content = [[notification userInfo] objectForKey:@"Object"];
	NSMutableString		*contentString = [[[content message] string] mutableCopy];
	
	if(contentString && [contentString length]){
		//We need to escape a few things to get our string to the javascript without trouble
		[contentString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
		[contentString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
		[contentString replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];

		//Now, feed the message to our javascript, which will append it to the bottom of the webview
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"documentAppend(\"%@\");", contentString]];
	}
}

//Dealloc
- (void)dealloc
{
    [super dealloc];
}

	
@end
