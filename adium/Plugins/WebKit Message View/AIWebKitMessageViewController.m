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
	plugin = [inPlugin retain];
    previousContent = nil;
	newContentTimer = nil;
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
	[newContentTimer invalidate]; [newContentTimer release];
	[plugin release]; plugin = nil;
	
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
		
		//Retain the style path for comparison with the new preference
		NSString		*oldStylePath = [stylePath retain];
		
		//Release the old preference cache
		[self _flushPreferenceCache];
		
		[[[adium preferenceController] preferenceForKey:KEY_WEBKIT_SHOW_USER_ICONS
												  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] boolValue];
		
		
		//Style and Variant preferences
		{
			NSString	*desiredStyle, *desiredVariant, *CSS;
			NSBundle	*style;
			
			desiredStyle = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_STYLE
																	group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
			style = [plugin messageStyleBundleWithName:desiredStyle];
			
			//If the preferred style is unavailable, load Smooth Operator
			if (!style){
				desiredStyle = @"Smooth Operator";
				style = [plugin messageStyleBundleWithName:desiredStyle];
			}
			
			stylePath = [[style resourcePath] retain];
				
			desiredVariant = [[adium preferenceController] preferenceForKey:[plugin keyForDesiredVariantOfStyle:desiredStyle]
																	  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];			
			CSS = (desiredVariant ? [NSString stringWithFormat:@"Variants/%@.css",desiredVariant] : @"main.css");
			
			//If we got here via a notification and the style did not change, update the webView to the current stylesheet.
			//If we got here from [self preferencesChanged:nil], prep the webView by loading our template.
			if (notification && [stylePath isEqualToString:oldStylePath]){
				[webView stringByEvaluatingJavaScriptFromString:
					[NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");", CSS]];
				
			}else{
				NSString	*basePath, *headerHTML, *footerHTML, *templateHTML;
				
				basePath = [[NSURL fileURLWithPath:stylePath] absoluteString];	
				headerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
				footerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
				
				//Load the template, and fill it up
				templateHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
				templateHTML = [NSString stringWithFormat:templateHTML, basePath, CSS, headerHTML, footerHTML];
				
				//Feed it to the webview
				[[webView mainFrame] loadHTMLString:templateHTML baseURL:nil];
			}
		}
		
		//Release the old style path
		[oldStylePath release];
	}
}

- (void)_flushPreferenceCache
{	
	[stylePath release];
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
