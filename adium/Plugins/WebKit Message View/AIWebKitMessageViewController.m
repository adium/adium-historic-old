//
//  AIWebKitMessageViewController.m
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 27 2004.
//

#import "AIWebKitMessageViewController.h"


@interface AIWebKitMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
- (void)appendChatChild:(NSString *)contentString;
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
	
	//Observe content
	[[adium notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:inChat];

	//Create our webview
	webView = [[WebView alloc] initWithFrame:NSMakeRect(0,0,100,100) //Arbitrary frame
								   frameName:nil
								   groupName:nil];
	[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	
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
	NSLog(@"%@",templateHTML);
	[[webView mainFrame] loadHTMLString:templateHTML
								baseURL:nil];
	
	
	
	
	
	
	
	//Time Stamps
#define PREF_GROUP_STANDARD_MESSAGE_DISPLAY	@"Message Display"
#define	KEY_SMV_TIME_STAMP_FORMAT		@"Time Stamp"
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
	timeStampFormat = [[prefDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT] retain];
	timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO];
	
	
	
	
	
	
	//Set it up with the javascript appender template
//	NSString	*path = [[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"xml"];
//	NSMutableString	*template = [[NSString stringWithContentsOfFile:path] mutableCopy];
//
//	//Stuff in the style information
//	NSRange	range = [template rangeOfString:@"%styles"];
//	
//	NSString *styleInfo = [NSString stringWithFormat:@"<?xml-stylesheet type=\"text/css\" href=\"file://%@/%@\"?>",[path stringByDeletingLastPathComponent],@"testlayout.css"];	
////	template = [styleInfo stringByAppendingString:template];
	
//	[template replaceCharactersInRange:range withString:styleInfo];
//	NSLog(@"template:%@",template);
//	
//	
//	
//	[[webView mainFrame] loadData:[template dataUsingEncoding:NSUTF8StringEncoding]
//						 MIMEType:@"text/xml"
//				 textEncodingName:@"utf-8"
//						  baseURL:nil/*[NSURL URLWithString:@"file:///Users/adamiser/Code/adium/Plugins/WebKit Message View"]*/];
//		
//		[NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]]];
//[NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]]
	
	
	
//	[[webView mainFrame] loadHTMLString:template
//								baseURL:nil/*[NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]]*/];
//
	
	
	
	
	
//	NSMutableString	*base = [@"hi" mutableCopy];;//[[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"xml"]] mutableCopy];
//
//	if(base && [base length]){
//		//We need to escape a few things to get our string to the javascript without trouble
//		[base replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0,[base length])];
//		[base replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[base length])];
//		[base replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[base length])];
//
//		//Now, feed the message to our javascript, which will append it to the bottom of the webview
//		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"documentAppend(\"%@\");", base]];
//	}
	
	
    return(self);
}

- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
	
	[super dealloc];
}

- (NSView *)messageView
{
	return(webView);
}

- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject		*content = [[notification userInfo] objectForKey:@"Object"];
	BOOL				contentIsSimilar = NO;
	
	if(previousContent && [[previousContent type] compare:[content type]] == 0 && [content source] == [previousContent source]){
		contentIsSimilar = YES;
	}
	
	
	
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        [self _addContentMessage:(AIContentMessage *)content similar:contentIsSimilar];
    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
        [self _addContentStatus:(AIContentStatus *)content similar:contentIsSimilar];
    }
	
	[previousContent release];
	previousContent = [content retain];
	
	
		
//	
//	
//	
//	NSMutableString		*contentString = [[[content message] string] mutableCopy];
//
//	NSLog(@"%@",webView);
//	NSLog(@"%@",[webView superview]);
//	NSLog(@"%@",[webView window]);
//	
//	NSString *child =
//	[NSString stringWithFormat:@"<message class=\"%@\"><name>%@</name><img class=\"usericon\" src=\"%@\" /><timestamp>%@</timestamp><body>%@</body></message>",
//				@"next",[[content source] displayName], @"http://homepage.mac.com/eevyl/eevylface2004.jpg", @"2:33", contentString];
//		
////	NSLog(@"%@",child);
//	
//	[self appendChatChild:child];
//
	
	
	
	
	
//	[webView stringByEvaluatingJavaScriptFromString:@"documentAppend();"];
	
//	AIContentObject		*content = [[notification userInfo] objectForKey:@"Object"];
//	NSMutableString		*contentString = [[[content message] string] mutableCopy];
//	
//	/*
//	 New sender?
//	   In?
//	     Append In Top
//	     Append In First Messasge
//	     Append In Bottom
//	   Out?
//    	 Append Out Top
//	 	 Append Out First Messasge
//	 	 Append Out Bottom
//	 Same sender?
//	 	In?
//	 		Append In Message above bottom
//	 	Out?
//			Append Out Message above bottom
//	 */
//	
//	
//	if(contentString && [contentString length]){
//		//We need to escape a few things to get our string to the javascript without trouble
//		[contentString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
//		[contentString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
//		[contentString replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
//
//		//Now, feed the message to our javascript, which will append it to the bottom of the webview
//		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"documentAppend(\"%@\");", contentString]];
//	}
}


- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar
{
	NSMutableString	*newHTML;
	

	NSString	*stylePath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"html"] stringByDeletingLastPathComponent];
	
	if([content isOutgoing]){
		stylePath = [stylePath stringByAppendingPathComponent:@"Outgoing"];
	}else{
		stylePath = [stylePath stringByAppendingPathComponent:@"Incoming"];
	}
	
	//
	NSString	*headerTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
	NSString	*footerTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
	NSString	*firstContentTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"FirstContent.html"]];
	NSString	*nextContentTemplate = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"NextContent.html"]];
	
	//New Bubble
	if(contentIsSimilar){
		newHTML = [NSMutableString stringWithFormat:@"%@", nextContentTemplate];
	}else{
		newHTML = [NSMutableString stringWithFormat:@"%@%@%@", headerTemplate, firstContentTemplate, footerTemplate];
	}
	
	//Fill in info
	NSRange	range;
	
	range = [newHTML rangeOfString:@"%sender"];
	if(range.location != NSNotFound){
		[newHTML replaceCharactersInRange:range withString:[[content source] displayName]];
	}
	
	range = [newHTML rangeOfString:@"%message"];
	if(range.location != NSNotFound){
		[newHTML replaceCharactersInRange:range withString:[[content message] string]];
	}
	
	range = [newHTML rangeOfString:@"%time"];
	if(range.location != NSNotFound){
		[newHTML replaceCharactersInRange:range withString:[timeStampFormatter stringForObjectValue:[(AIContentMessage *)content date]]];
	}
	
	if(contentIsSimilar){
		[self appendMessageChild:newHTML];
	}else{
		[self appendChatChild:newHTML];
	}
	
	
}

- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar
{

	
}





- (void)appendChatChild:(NSString *)inString
{
	if(inString && [inString length]){
		NSMutableString	*contentString = [[inString mutableCopy] autorelease];
		
		//We need to escape a few things to get our string to the javascript without trouble
		[contentString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
		[contentString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
		[contentString replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];

		//Now, feed the message to our javascript, which will append it to the bottom of the webview
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"checkIfScrollToBottomIsNeeded(); documentAppend(\"%@\"); scrollToBottomIfNeeded();", contentString]];
	}
}

- (void)appendMessageChild:(NSString *)inString
{
	if(inString && [inString length]){
		NSMutableString	*contentString = [[inString mutableCopy] autorelease];
		
		//We need to escape a few things to get our string to the javascript without trouble
		[contentString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
		[contentString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];
		[contentString replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[contentString length])];

		//Now, feed the message to our javascript, which will append it to the bottom of the webview
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"checkIfScrollToBottomIsNeeded(); documentAppendMessage(\"%@\"); scrollToBottomIfNeeded();", contentString]];
	}
}

@end
