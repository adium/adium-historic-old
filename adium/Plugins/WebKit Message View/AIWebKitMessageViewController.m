//
//  AIWebKitMessageViewController.m
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
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
	AIContentObject	*content = [[notification userInfo] objectForKey:@"Object"];

	NSLog(@"%@",[[content message] string]);
	NSLog(@" %@",[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"checkIfScrollToBottomIsNeeded(); documentAppend('%@'); scrollToBottomIfNeeded();", [[content message] string]]]);

}

//Dealloc
- (void)dealloc
{
    [super dealloc];
}

	
@end
