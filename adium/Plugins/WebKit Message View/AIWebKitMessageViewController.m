//
//  AIWebKitMessageViewController.m
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 27 2004.
//

#import "AIWebKitMessageViewController.h"
#import "ESWebFrameViewAdditions.h"

#define NEW_CONTENT_RETRY_DELAY 0.01

@interface AIWebKitMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar;
- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content;
- (NSMutableString *)escapeString:(NSMutableString *)inString;
- (void)processNewContent;
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
    previousContent = nil;
	newContentTimer = nil;
	webViewIsReady = NO;
	newContent = [[NSMutableArray alloc] init];
	
	//Observe content
	[[adium notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:inChat];

	//Create our webview
	webView = [[WebView alloc] initWithFrame:NSMakeRect(0,0,100,100) //Arbitrary frame
								   frameName:nil
								   groupName:nil];
	[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[webView setFrameLoadDelegate:self];
	[webView setPolicyDelegate:self];
	[[[webView mainFrame] frameView] setAllowsHorizontalScrolling:YES];

	//We'd load this information from a file or plist or something
	NSString	*stylePath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"html"] stringByDeletingLastPathComponent];
	NSString	*basePath = [[NSURL fileURLWithPath:stylePath] absoluteString];
	NSString	*mainCSS = @"test.css";
	NSString	*variantCSS = @"testlayout.css";
	NSString	*headerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
	NSString	*footerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
	
	//Load the template, and fill it up
	NSString	*templateHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
	templateHTML = [NSString stringWithFormat:templateHTML, basePath, mainCSS, variantCSS, headerHTML, footerHTML];
    
	//Feed it to the webview
	[[webView mainFrame] loadHTMLString:templateHTML baseURL:nil];
	
	//Time Stamps
#define PREF_GROUP_STANDARD_MESSAGE_DISPLAY	@"Message Display"
#define	KEY_SMV_TIME_STAMP_FORMAT		@"Time Stamp"
	
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
	timeStampFormat = [[prefDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT] retain];
	timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO];
	
    return(self);
}

- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
	[newContent release];
	[newContentTimer invalidate]; [newContentTimer release];
	
	[super dealloc];
}

- (NSView *)messageView
{
	return(webView);
}

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
		BOOL			contentIsSimilar = NO;
		
		//
		if(previousContent && [[previousContent type] compare:[content type]] == 0 && [content source] == [previousContent source]){
			contentIsSimilar = YES;
		}

		//
		if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
			[self _addContentMessage:(AIContentMessage *)content similar:contentIsSimilar];
		}else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
			[self _addContentStatus:(AIContentStatus *)content similar:contentIsSimilar];
		}
		
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

- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar
{
	NSString		*stylePath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"html"] stringByDeletingLastPathComponent];
	NSMutableString	*newHTML;
	
	//
	if([content isOutgoing]){
		stylePath = [stylePath stringByAppendingPathComponent:@"Outgoing"];
	}else{
		stylePath = [stylePath stringByAppendingPathComponent:@"Incoming"];
	}
	
	//
	NSString	*contentTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Content.html"]];
	NSString	*nextContentTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"NextContent.html"]];
	
	//
	if(!contentIsSimilar){
		newHTML = [[contentTemplate mutableCopy] autorelease];
		newHTML = [self fillKeywords:newHTML forContent:content];
		newHTML = [self escapeString:newHTML];
        
		[webView stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();", newHTML]];
		
	}else{
		newHTML = [[nextContentTemplate mutableCopy] autorelease];
		newHTML = [self fillKeywords:newHTML forContent:content];
		newHTML = [self escapeString:newHTML];
		
		[webView stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"checkIfScrollToBottomIsNeeded(); appendNextMessage(\"%@\"); scrollToBottomIfNeeded();", newHTML]];
		
	}
}

- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar
{
    NSString        *stylePath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"html"] stringByDeletingLastPathComponent];
	NSMutableString *newHTML;
    NSString	    *statusTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Status.html"]];
	
	newHTML = [[statusTemplate mutableCopy] autorelease];
	newHTML = [self fillKeywords:newHTML forContent:content];
	newHTML = [self escapeString:newHTML];
	
	[webView stringByEvaluatingJavaScriptFromString:
	   [NSString stringWithFormat:@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();", newHTML]];
}

//
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content
{
	NSRange	range;
	
	if ([content isKindOfClass:[AIContentMessage class]]) {
		
        range = [inString rangeOfString:@"%senderScreenName%"];
        if(range.location != NSNotFound){
           [inString replaceCharactersInRange:range withString:[[content source] UID]];
        }
        
        range = [inString rangeOfString:@"%sender%"];
        if(range.location != NSNotFound){
            [inString replaceCharactersInRange:range withString:[[content source] displayName]];
        }
        
        range = [inString rangeOfString:@"%service%"];
        if(range.location != NSNotFound){
           [inString replaceCharactersInRange:range withString:[[content source] serviceID]];
        }
#warning This disables any fonts in the webkit view other than what is specified by the template.
        range = [inString rangeOfString:@"%message%"];
        if(range.location != NSNotFound){
            // Using a safeString so image attachments are removed
            // while waiting for a permanent fix that would allows us to use emoticons
            [inString replaceCharactersInRange:range withString:
              [AIHTMLDecoder encodeHTML:[[(AIContentMessage *)content message] safeString]
                  headers:NO fontTags:NO closeFontTags:NO styleTags:YES 
                  closeStyleTagsOnFontChange:NO encodeNonASCII:YES 
                  imagesPath:@"/tmp"]];
        }
		
        range = [inString rangeOfString:@"%time%"];
        if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range withString:[timeStampFormatter stringForObjectValue:[(AIContentMessage *)content date]]];
        }

		//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
		range = [inString rangeOfString:@"%time{"];
        if(range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%"];
			if(endRange.location != NSNotFound && endRange.location > range.location + range.length) {

				NSRange textRange = NSMakeRange(range.location + range.length, (endRange.location - range.location - range.length));
				NSRange finalRange = NSMakeRange(range.location, (endRange.location - range.location) + endRange.length);
				
				NSString *timeFormat = [inString substringWithRange:textRange];
				
				[inString replaceCharactersInRange:finalRange withString:[[[NSDateFormatter alloc] initWithDateFormat:timeFormat allowNaturalLanguage:NO] stringForObjectValue:[(AIContentMessage *)content date]]];
				
			}
        }
		
	} else {
        range = [inString rangeOfString:@"%message%"];
        if(range.location != NSNotFound){
            [inString replaceCharactersInRange:range withString:[(AIContentStatus *)content message]];
        }
        
        range = [inString rangeOfString:@"%time%"];
        if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range withString:[timeStampFormatter stringForObjectValue:[(AIContentStatus *)content date]]];
        }
		
		range = [inString rangeOfString:@"%status%"];
		if(range.location != NSNotFound) {
			[inString replaceCharactersInRange:range withString:[(AIContentStatus *)content status]];
		}
	}
	
	return(inString);
}

//
- (NSMutableString *)escapeString:(NSMutableString *)inString
{
	//We need to escape a few things to get our string to the javascript without trouble
	[inString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0,[inString length])];
	[inString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[inString length])];
	[inString replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[inString length])];
	[inString replaceOccurrencesOfString:@"\r" withString:@"<br />" options:NSLiteralSearch range:NSMakeRange(0,[inString length])];
	return(inString);
}


//----WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	webViewIsReady = YES;
	//NSLog(@"Ready");
}

// WebPolicyDelegate
- (void)webView:(WebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
    request:(NSURLRequest *)request
    frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    int actionKey = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    if (actionKey == WebNavigationTypeOther) {
        [listener use];
    } else {
        [[NSWorkspace sharedWorkspace] openURL: [request URL]];
    }
}

@end
