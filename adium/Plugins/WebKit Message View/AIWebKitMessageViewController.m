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
	[webView unregisterDraggedTypes]; 
	
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


//WebView preferences --------------------------------------------------------------------------------------------------
#pragma mark WebView preferences
//The controller observes for preferences which are applied to the WebView
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY]){
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
			NSString *variant, *CSS;
			
			variant = [[adium preferenceController] preferenceForKey:[plugin variantKeyForStyle:styleName]
																	  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];			
			CSS = (variant ? [NSString stringWithFormat:@"Variants/%@.css",variant] : @"main.css");
			
			allowColors = [plugin boolForKey:@"AllowTextColors" style:style variant:variant boolDefault:YES];
			
			if (notification){
				[webView stringByEvaluatingJavaScriptFromString:
					[NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");", CSS]];
				
			}else{

				[stylePath release];
				stylePath = [[style resourcePath] retain];

				[plugin loadStyle:style 
						 withName:styleName
						  variant:variant
						  withCSS:CSS
						  forChat:chat
					  intoWebView:webView];
			}
		}
	}
}

- (void)_flushPreferenceCache
{	
	
}


//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
//Content was added
- (void)contentObjectAdded:(NSNotification *)notification
{
	[newContent addObject:[[notification userInfo] objectForKey:@"Object"]];
	[self processNewContent];	
}

//Process any content waiting to be displayed
- (void)processNewContent
{
	while(webViewIsReady && [newContent count]){
		AIContentObject *content = [newContent objectAtIndex:0];
		
		//Display the content
		[plugin processContent:content
		   withPreviousContent:previousContent 
					forWebView:webView
				 fromStylePath:stylePath
				allowingColors:allowColors];

		//Remember the last content inserted (Used mainly for combining consecutive messages)
		[previousContent release];
		previousContent = [content retain];

		//Remove the content we just displayed from the queue
		if ([newContent count]){
			[newContent removeObjectAtIndex:0];
		}
	}
	
	//We no longer need the update timer
	if(newContentTimer){
		[newContentTimer invalidate]; [newContentTimer release];
		newContentTimer = nil;
	}
	
	//If we still have content to process, we'll try again after a brief delay
	if([newContent count]){
		newContentTimer = [[NSTimer scheduledTimerWithTimeInterval:NEW_CONTENT_RETRY_DELAY
															target:self
														  selector:@selector(processNewContent)
														  userInfo:nil
														   repeats:NO] retain]; 
	}
}


//WebView Delegates ----------------------------------------------------------------------------------------------------
#pragma mark WebFrameLoadDelegate
//Called once the webview has loaded and is ready to accept content
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	//Flag the view as ready (as soon as the current methods exit) so we know it's now safe to add content
	[self performSelector:@selector(webViewIsReady) withObject:nil afterDelay:0.0001];
}
- (void)webViewIsReady{
	webViewIsReady = YES;
}

//Prevent the webview from following external links.  We direct these to the users web browser.
- (void)webView:(WebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
    request:(NSURLRequest *)request
    frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    int actionKey = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    if (actionKey == WebNavigationTypeOther){
		[listener use];
    } else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		[[NSWorkspace sharedWorkspace] openURL:url];
		[listener ignore];
    }
}

@end
