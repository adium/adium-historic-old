//
//  AIWebKitMessageViewController.m
//  Adium
//
//  Created by Adam Iser on Fri Feb 27 2004.
//

#import "AIWebKitMessageViewController.h"
//#import "ESWebFrameViewAdditions.h"



@interface AIWebKitMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_flushPreferenceCache;
- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar;
- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content;
- (NSMutableString *)escapeString:(NSMutableString *)inString;
- (void)processNewContent;
@end

@implementation AIWebKitMessageViewController

//Create a new message view
+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin
{
    return([[[self alloc] initForChat:inChat withPlugin:inPlugin] autorelease]);
}

//Init
- (id)initForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin
{
    //init
    [super init];
	chat = [inChat retain];
	plugin = [inPlugin retain];
    previousContent = nil;
	newContentTimer = nil;
	stylePath = nil;
	webViewIsReady = NO;
	newContent = [[NSMutableArray alloc] init];
	
	//Observe content
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(contentObjectAdded:)
									   name:Content_ContentObjectAdded 
									 object:inChat];

	//Create our webview
	webView = [[ESWebView alloc] initWithFrame:NSMakeRect(0,0,100,100) //Arbitrary frame
									 frameName:nil
									 groupName:nil];
	
	[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[webView setFrameLoadDelegate:self];
	[webView setPolicyDelegate:self];
	[webView setUIDelegate:self];
	[webView setMaintainsBackForwardList:NO];

//	[[[[[webView mainFrame] frameView] documentView] enclosingScrollView] setAllowsHorizontalScrolling:NO];
	
	//Observe preference changes and set our initial preferences
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	[self preferencesChanged:nil];
	
    return(self);
}

- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
	[newContent release];
	[previousContent release];
	[newContentTimer invalidate]; [newContentTimer release];
	[plugin release]; plugin = nil;
	[chat release]; chat = nil;
	
	[super dealloc];
}

//Return the view which should be inserted into the message window
- (NSView *)messageView
{
	return webView;
}

//Return our scroll view
- (NSView *)messageScrollView
{
	return([[webView mainFrame] frameView]);
}

#pragma mark WebView preferences
//The controller observes for preferences which are applied to the WebView
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] == 0){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
		NSString	*styleName, *newStylePath;
		NSBundle	*style;
		
		styleName = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_STYLE
															 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		style = [plugin messageStyleBundleWithName:styleName];
		
		//If the preferred style is unavailable, load the default
		if (!style){
			styleName = AILocalizedString(@"Mockie","Default message style name. Make sure this matches the localized style bundle's name!");
			style = [plugin messageStyleBundleWithName:styleName];
		}
		
		newStylePath = [style resourcePath];
		
		//If preferences changed but the style did not change, update the webView to the current stylesheet.
		//If we got here from [self preferencesChanged:nil], prep the webView by loading our template.
		//Note that we do not support open windows changing styles; new styles only affect new windows.
		//Variants and font settings and such can change midstream.
		if (!notification ||  (stylePath && [stylePath isEqualToString:newStylePath])){
			NSString *desiredVariant, *CSS;
			
			desiredVariant = [[adium preferenceController] preferenceForKey:[plugin variantKeyForStyle:styleName]
																	  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];			
			CSS = (desiredVariant ? [NSString stringWithFormat:@"Variants/%@.css",desiredVariant] : @"main.css");
			
			
			if (notification){
				[webView stringByEvaluatingJavaScriptFromString:
					[NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");", CSS]];
				
			}else{
				NSString	*basePath, *headerHTML, *footerHTML;
				NSMutableString *templateHTML;
				
				[stylePath release];
				stylePath = [newStylePath retain];
				
				[plugin loadPreferencesForWebView:webView withStyleNamed:styleName];
				
				
				basePath = [[NSURL fileURLWithPath:stylePath] absoluteString];	
				headerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
				footerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
				templateHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
				
				templateHTML = [NSMutableString stringWithFormat:templateHTML, basePath, CSS, headerHTML, footerHTML];
				templateHTML = [plugin fillKeywords:templateHTML forStyle:style forChat:chat];
				
				//Feed it to the webview
				[[webView mainFrame] loadHTMLString:templateHTML baseURL:nil];
			}
		}
	}
}

- (void)_flushPreferenceCache
{	
	
}

#pragma mark Content
- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject		*content = [[notification userInfo] objectForKey:@"Object"];

	//Add
	[newContent addObject:content];
	[self processNewContent];	
}

- (void)processNewContent
{
	while(webViewIsReady && [newContent count]){
		AIContentObject *content = [newContent objectAtIndex:0];
		
		[plugin processContent:content withPreviousContent:previousContent forWebView:webView fromStylePath:stylePath];

		//
		[previousContent release];
		previousContent = [content retain];

		//de-queue
		[newContent removeObjectAtIndex:0];
	}
	
	//cleanup previous 
	if(newContentTimer){
		[newContentTimer invalidate]; [newContentTimer release];
		newContentTimer = nil;
	}
	
	//if not added, Try to add this content again in a little bit
	if([newContent count]){
		newContentTimer = [[NSTimer scheduledTimerWithTimeInterval:NEW_CONTENT_RETRY_DELAY
															target:self
														  selector:@selector(processNewContent)
														  userInfo:nil
														   repeats:NO] retain]; 
	}
}

#pragma mark WebFrameLoadDelegate
//----WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	webViewIsReady = YES;
}

#pragma mark WebPolicyDelegate
//----WebPolicyDelegate
- (void)webView:(WebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
    request:(NSURLRequest *)request
    frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
//	NSLog(@"decidePolicyForNavigationAction:%@ %@ %@ %@",actionInformation,request,frame,listener);
	
    int actionKey = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    if (actionKey == WebNavigationTypeOther) {
        [listener use];
    } else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		[[NSWorkspace sharedWorkspace] openURL:url];	
		[listener ignore];
    }
}

#pragma mark Web
@end
