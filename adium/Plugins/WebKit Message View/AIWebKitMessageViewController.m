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
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forStyle:(NSBundle *)style variant:(NSString *)variant;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString;
- (NSMutableString *)escapeString:(NSMutableString *)inString;
- (void)processNewContent;
- (void)_processContentObject:(AIContentObject *)content;
- (void)participatingListObjectsChanged:(NSNotification *)notification;
- (void)loadStyle:(NSBundle *)style withCSS:(NSString *)CSS;
- (void)_loadPreferencesWithStyleNamed:(NSString *)styleName;
- (void)setVariantID:(NSString *)variantID;
- (void)refreshView;
- (void)_completeVariantIDSet:(NSString *)setStylesheetJavaScript;
@end

@implementation AIWebKitMessageViewController

DeclareString(AppendMessageWithScroll);
DeclareString(AppendNextMessageWithScroll);
DeclareString(AppendMessage);
DeclareString(AppendNextMessage);

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
	
	InitString(AppendMessageWithScroll,@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();");
	InitString(AppendNextMessageWithScroll,@"checkIfScrollToBottomIsNeeded(); appendNextMessage(\"%@\"); scrollToBottomIfNeeded();");
	InitString(AppendMessage,@"appendMessage(\"%@\");");
	InitString(AppendNextMessage,@"appendNextMessage(\"%@\");");
	
	chat = [inChat retain];
	plugin = [inPlugin retain];
    previousContent = nil;
	newContentTimer = nil;
	stylePath = nil;
	background = nil;
	backgroundColor = nil;
	loadedStyleID = nil;
	setStylesheetTimer = nil;
	
	webViewIsReady = NO;
	newContent = [[NSMutableArray alloc] init];
//	webUserIconArray = [[NSMutableArray alloc] init];
		
	//Observe list objects we need to concern ourselves with
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(participatingListObjectsChanged:)
									   name:Content_ChatParticipatingListObjectsChanged 
									 object:chat];
	[self participatingListObjectsChanged:nil];
	
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
		
	//Observe preference changes. Our initial preferences are also applied by refreshView, so no need for an explicit
	//[self prefrencesChanged:nil] call here.
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

	[self refreshView];
	
    return(self);
}

- (void)dealloc
{
	[newContentTimer invalidate]; [newContentTimer release]; newContentTimer = nil;	
	[[adium notificationCenter] removeObserver:self];
	
	//Stop being the webView's baby's daddy; the webView may attempt callbacks shortly after we dealloc
	[webView setFrameLoadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setUIDelegate:nil];
	
	[newContent release]; newContent = nil;
	[previousContent release]; previousContent = nil;
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

- (void)_refreshContent
{
	[newContent removeAllObjects];
	[newContent addObjectsFromArray:[chat contentObjectArray]];
	[self processNewContent];	
}


//User Icons
#pragma mark Participating List Objects & User Icons

//We want to observe attributedChanged: notifications for all objects which are participating in our chat.
//When the list changes, remove the observers we had in place before and add observers for each object in the list
//so we never observe for contacts not in the chat.
- (void)participatingListObjectsChanged:(NSNotification *)notification
{
	NSNotificationCenter	*notificationCenter = [adium notificationCenter];
	NSString				*attributesChangedNotification = ListObject_AttributesChanged;
	
	[notificationCenter removeObserver:self
								  name:attributesChangedNotification
								object:nil];
	
	NSEnumerator	*enumerator = [[chat participatingListObjects] objectEnumerator];
	AIListObject	*object;
	
	while (object = [enumerator nextObject]){
		[notificationCenter addObserver:self 
							   selector:@selector(listObjectAttributesChanged:) 
								   name:attributesChangedNotification
								 object:object];
	}
}

- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	
}
//- (void)

//WebView preferences --------------------------------------------------------------------------------------------------
#pragma mark WebView preferences
//The controller observes for preferences which are applied to the WebView
//Variant changes are applied immediately, but all other changes must wait
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY]){

		NSString	*notificationKey = [[notification userInfo] objectForKey:@"Key"];
		NSString	*key = [plugin variantKeyForStyle:loadedStyleID];

		if(notification == nil ||
		   notificationKey == nil ||
		   [notificationKey isEqualToString:key]){
			NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];

			NSString	*styleID = [prefDict objectForKey:KEY_WEBKIT_STYLE];
			
			if([loadedStyleID isEqualToString:styleID]){
				[self setVariantID:[prefDict objectForKey:key]];
			}
		}
	}
}

//Change style variant only (leaving style alone)
- (void)setVariantID:(NSString *)variantID
{
	if(!loadedVariantID || [variantID compare:loadedVariantID] != 0){
		
		if (setStylesheetTimer) {
			[setStylesheetTimer invalidate]; [setStylesheetTimer release];
		}
		
		if (webViewIsReady){
			[self _completeVariantIDSet:variantID];
			
		}else{
			setStylesheetTimer = [[NSTimer scheduledTimerWithTimeInterval:NEW_CONTENT_RETRY_DELAY
																   target:self
																 selector:@selector(_tryToCompleteVariantIDSetTimer:)
																 userInfo:variantID
																  repeats:YES] retain];
		}
	}	
}
//We weren't ready last time; keep checking until the webView is ready to receive our command
- (void)_tryToCompleteVariantIDSetTimer:(NSTimer *)inTimer
{
	if (webViewIsReady){
		NSString	*variantID = [setStylesheetTimer userInfo];
		[self _completeVariantIDSet:variantID];
		
		//Timer isn't needed anymore
		[setStylesheetTimer invalidate]; [setStylesheetTimer release]; setStylesheetTimer = nil;
	}
}
- (void)_completeVariantIDSet:(NSString *)variantID
{
	//Load and apply the new variant
	NSString	*cssPath = ([variantID length] ? [NSString stringWithFormat:@"Variants/%@.css",variantID] : @"main.css");
	NSString	*setStylesheetJavaScript =   [NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");", cssPath];
	
	[webView stringByEvaluatingJavaScriptFromString:setStylesheetJavaScript];
	//Remember this variant ID
	[loadedVariantID release]; loadedVariantID = [variantID retain];
}

- (void)refreshView
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	NSString		*CSS, *newStylePath;
	NSBundle		*style;
	
	//Release the old preference cache
	[self _flushPreferenceCache];
	
	//
	{			
		//Set up a time stamp format based on this user's locale
		NSString    *format = [prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT];
		
		if(!format || [format length] == 0){
			format = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO];
			[[adium preferenceController] setPreference:format
												 forKey:KEY_WEBKIT_TIME_STAMP_FORMAT
												  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		}
		
		timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO];
		
		showUserIcons = [[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue];
		useCustomNameFormat = [[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue];
		nameFormat = [[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue];
		combineConsecutive = [[prefDict objectForKey:KEY_WEBKIT_COMBINE_CONSECUTIVE] boolValue];
	}
	
	loadedStyleID = [[prefDict objectForKey:KEY_WEBKIT_STYLE] retain];
	style = [plugin messageStyleBundleWithName:loadedStyleID];
	
	//If the preferred style is unavailable, load the default
	if (!style){
		[loadedStyleID release];
		loadedStyleID = AILocalizedString(@"Mockie","Default message style name. Make sure this matches the localized style bundle's name!");
		style = [plugin messageStyleBundleWithName:loadedStyleID];
	}
	newStylePath = [style resourcePath];
	
	loadedVariantID = [[prefDict objectForKey:[plugin variantKeyForStyle:loadedStyleID]] retain];
	CSS = ([loadedVariantID length] ? [NSString stringWithFormat:@"Variants/%@.css",loadedVariantID] : @"main.css");
	
	allowColors = [plugin boolForKey:@"AllowTextColors" style:style variant:loadedVariantID boolDefault:YES];
	
	allowBackgrounds = ![plugin boolForKey:@"DisableCustomBackground"
									 style:style 
								   variant:loadedVariantID
							   boolDefault:NO];
	
	//Background Preferences [Style specific]
	[background release]; background = nil;
	[backgroundColor release]; backgroundColor = nil;
	if(allowBackgrounds){
		background = [[prefDict objectForKey:[plugin backgroundKeyForStyle:loadedStyleID]] retain];
		backgroundColor = [[[prefDict objectForKey:[plugin backgroundColorKeyForStyle:loadedStyleID]] representedColor] retain];
	}
	
	[stylePath release];
	stylePath = [[style resourcePath] retain];
	
	[self loadStyle:style 
			withCSS:CSS];
}

- (void)_flushPreferenceCache
{
	[loadedStyleID release];
	[loadedVariantID release];
	[timeStampFormatter release];
}

//Force this view to immediately switch to the current preferences and then redisplay all its content
//This may be very slow for a large conversation.
- (void)forceReload
{
	[self refreshView];
	[self _refreshContent];
}

- (void)loadStyle:(NSBundle *)style withCSS:(NSString *)CSS
{
	NSString		*headerHTML, *footerHTML;
	NSMutableString *templateHTML;
	NSString		*basePath = [[NSURL fileURLWithPath:stylePath] absoluteString];	
	
	//Our styles are versioned so we can change how they work without breaking compatability
	/*
	 Version 0: Initial Webkit Version
	 Version 1: Template.html now handles all scroll-to-bottom functionality.  It is no longer required to call the
	 			scrollToBottom functions when inserting content.
	 */
	styleVersion = [[style objectForInfoDictionaryKey:KEY_WEBKIT_VERSION] intValue];
	
	//Load the style's templates
	//We can't use NSString's initWithContentsOfFile here.  HTML files are interpreted in the defaultCEncoding
	//(which varies by system) when read that way.  We want to always interpret the files as ASCII.
	headerHTML = [NSString stringWithContentsOfASCIIFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
	footerHTML = [NSString stringWithContentsOfASCIIFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
	templateHTML = [NSMutableString stringWithContentsOfASCIIFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
	
	//Starting with version 1, styles can choose to not include template.html.  If the template is not included 
	//Adium's default will be used.  This is preferred since any future template updates will apply to the style
	if((!templateHTML || [templateHTML length] == 0) && styleVersion >= 1){		
		templateHTML = [NSMutableString stringWithContentsOfASCIIFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Template" ofType:@"html"]];
	}
	templateHTML = [NSMutableString stringWithFormat:templateHTML, basePath, CSS, headerHTML, footerHTML];
	templateHTML = [self fillKeywords:templateHTML];
	
	//Load the style's preferences
	[self _loadPreferencesWithStyleNamed:loadedStyleID];
	
	//Load all the templates we'll need to for handling content
	{
		//Content Templates
		contentInHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Incoming/Content.html"]] retain];
		nextContentInHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Incoming/NextContent.html"]] retain];
		contentOutHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Outgoing/Content.html"]] retain];
		nextContentOutHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Outgoing/NextContent.html"]] retain];
		
		//Context (Fall back on content if not present)
		contextInHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Incoming/Context.html"]] retain];
		nextContextInHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Incoming/NextContext.html"]] retain];
		if(!contextInHTML) contextInHTML = [contentInHTML retain];
		if(!nextContextInHTML) nextContextInHTML = [nextContentInHTML retain];
		
		contextOutHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Outgoing/Context.html"]] retain];
		nextContextOutHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Outgoing/NextContext.html"]] retain];
		if(!contextOutHTML) contextOutHTML = [contentOutHTML retain];
		if(!nextContextOutHTML) nextContextOutHTML = [nextContentOutHTML retain];
		
		//Status
		statusHTML = [[NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Status.html"]] retain];
	}
	
	
	//Feed it to the webview
	webViewIsReady = NO;
	[[webView mainFrame] loadHTMLString:templateHTML baseURL:nil];
}


- (void)_loadPreferencesWithStyleNamed:(NSString *)styleName
{
	NSString	*prefIdentifier = [NSString stringWithFormat:@"Adium Style %@ Preferences",styleName];
	[webView setPreferencesIdentifier:prefIdentifier];
	[[webView preferences] setAutosaves:YES];
	
	if (![[[adium preferenceController] preferenceForKey:prefIdentifier
												   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] boolValue]){
		
		//Load defaults from the bundle or our defaults, as appropriate
		NSBundle	*style = [plugin messageStyleBundleWithName:styleName];
		
		NSString	*defaultFontFamily = [style objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_FAMILY];
		if (!defaultFontFamily){
			defaultFontFamily = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_DEFAULT_FONT_FAMILY
																		 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		}
		
		NSNumber	*defaultSizeNumber = [style objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_SIZE];
		if (!defaultSizeNumber){
			defaultSizeNumber = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_DEFAULT_FONT_SIZE
																		 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		}
		
		[webView setFontFamily:defaultFontFamily];
		[[webView preferences] setDefaultFontSize:[defaultSizeNumber intValue]];
		
		//We have no created a webView preferences object and configured its defaults, so no need to do it again
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:prefIdentifier
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}
	
	//This is really weird.  defaultFontSize returns the proper value, but we have to do setDefaultFontSize with it for it to be applied.
	[[webView preferences] setDefaultFontSize:[[webView preferences] defaultFontSize]];
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
		[self _processContentObject:content];

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

- (void)processContent:(AIContentObject *)content
{
	NSString		*dateMessage = nil;
	AIContentStatus *dateSeparator = nil;
	BOOL			contentIsSimilar = NO;
	BOOL			shouldShowDateHeader = NO;
    NSCalendarDate *previousDate = [[previousContent date] dateWithCalendarFormat:nil
                                                                         timeZone:nil];
    NSCalendarDate *currentDate = [[content date] dateWithCalendarFormat:nil 
                                                                timeZone:nil];
	// Should we merge consecutive messages?
	if((previousContent) &&
	   ([[previousContent type] isEqualToString:[content type]]) && 
	   ([content source] == [previousContent source]) &&
	   ([currentDate timeIntervalSinceDate:previousDate] <= 300)){
		contentIsSimilar = YES;
	}
	
	if ([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
		if(previousContent) {
			// Are the messages history lines from different days?
			if( [previousDate dayOfCommonEra] != [currentDate dayOfCommonEra] ) {
				contentIsSimilar = NO;
				shouldShowDateHeader = YES;
			}
		} else {		
			// If no previous content and we have history messages, show a date header
			shouldShowDateHeader = YES;			
		}
		
		// Add the date header (should be farmed out to a separate function)
		if( shouldShowDateHeader ) {
						
			dateMessage = [[NSDateFormatter localizedDateFormatter] stringForObjectValue:[(AIContentContext *)content date]];
			
			dateSeparator = [AIContentStatus statusInChat:[content chat]
											   withSource:[[content chat] listObject]
											  destination:[[content chat] account]
													 date:[content date]
												  message:[NSAttributedString stringWithString:dateMessage]
												 withType:@"date_separator"];
			//Add the date header
			[self _addContentStatus:dateSeparator similar:NO];
		}
	}
	
	// If there was history and we're at the end of it, add a line with the current date
	if(previousContent && [[content type] compare:CONTENT_MESSAGE_TYPE] == 0 && [[previousContent type] compare:CONTENT_CONTEXT_TYPE] == 0) {
		
		NSCalendarDate *previousDate = [[(AIContentContext *)previousContent date] dateWithCalendarFormat:nil
																								 timeZone:nil];
			
		// Was the last history from a different day?
		if( [previousDate dayOfCommonEra] != [[[NSDate date] dateWithCalendarFormat:nil
																		   timeZone:nil] dayOfCommonEra] ) {
			
			dateMessage = [[NSDateFormatter localizedDateFormatter] stringForObjectValue:[NSDate date]];
		
			dateSeparator = [AIContentStatus statusInChat:[content chat]
										   withSource:[[content chat] listObject]
										  destination:[[content chat] account]
												 date:[content date]
											  message:[NSAttributedString stringWithString:dateMessage]
											 withType:@"date_separator"];
			//Add the date header
			[self _addContentStatus:dateSeparator similar:NO];
		
		}
	}
		
	if([[content type] isEqualToString:CONTENT_MESSAGE_TYPE] || [[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
		[self _addContentMessage:(AIContentMessage *)content 
						   similar:contentIsSimilar];
		
	}else if([[content type] isEqualToString:CONTENT_STATUS_TYPE]){
		[self _addContentStatus:(AIContentStatus *)content
						  similar:contentIsSimilar];
	}
}
//Display a content object
- (void)_processContentObject:(AIContentObject *)content
{
	NSString		*dateMessage = nil;
	AIContentStatus *dateSeparator = nil;
	BOOL			contentIsSimilar = NO;
	BOOL			shouldShowDateHeader = NO;
    NSCalendarDate *previousDate = [[previousContent date] dateWithCalendarFormat:nil timeZone:nil];
    NSCalendarDate *currentDate = [[content date] dateWithCalendarFormat:nil timeZone:nil];
	
	//Should we merge consecutive messages?
	contentIsSimilar = (previousContent && [content isSimilarToContent:previousContent]);
	
	//If the day has changed since our last message (or if there was no previous message), insert a date line
	if(!previousContent && [content isFromSameDayAsContent:previousContent]){
		dateMessage = [[content date] descriptionWithCalendarFormat:[[NSDateFormatter localizedDateFormatter] dateFormat]
														   timeZone:nil
															 locale:nil];
		dateSeparator = [AIContentStatus statusInChat:[content chat]
										   withSource:[[content chat] listObject]
										  destination:[[content chat] account]
												 date:[content date]
											  message:[NSAttributedString stringWithString:dateMessage]
											 withType:@"date_separator"];
		//Add the date header
		[self _addContentStatus:dateSeparator similar:NO];
	}
	
	//Add the content objects
	if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0 || [[content type] compare:CONTENT_CONTEXT_TYPE] == 0){
		[self _addContentMessage:(AIContentMessage *)content similar:contentIsSimilar];
		
	}else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
		[self _addContentStatus:(AIContentStatus *)content similar:contentIsSimilar];
	}
}

//Append a content message
- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar
{	
	BOOL			isContext = [[content type] isEqualToString:CONTENT_CONTEXT_TYPE];
	NSString		*format, *templateFile;
	NSMutableString	*newHTML;
	
	//Disable color for context
	if(isContext) allowColors = NO;
	if(!combineConsecutive) contentIsSimilar = NO;
	
	//Get the correct template for what we're inserting
	if([content isOutgoing]){
		if(contentIsSimilar && combineConsecutive){
			templateFile = [(isContext ? nextContextOutHTML : nextContentOutHTML) mutableCopy];
		}else{
			templateFile = [(isContext ? contextOutHTML : contentOutHTML) mutableCopy];
		}
	}else{
		if(contentIsSimilar && combineConsecutive){
			templateFile = [(isContext ? nextContextInHTML : nextContentInHTML) mutableCopy];
		}else{
			templateFile = [(isContext ? contextInHTML : contentInHTML) mutableCopy];
		}
	}
	
	//Perform substitutions, then escape the HTML to get it past the evil javascript guards
	newHTML = [[templateFile mutableCopy] autorelease];
	newHTML = [self fillKeywords:newHTML forContent:content];
	newHTML = [self escapeString:newHTML];
	
	//Append the message to our webkit view
	if(styleVersion >= 1){
		format = (contentIsSimilar ? AppendNextMessage : AppendMessage);
	}else{
		format = (contentIsSimilar ? AppendNextMessageWithScroll : AppendMessageWithScroll);
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:format, newHTML]];	
}

//Append a content status
- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar
{
	NSMutableString	*newHTML = [[statusHTML mutableCopy] autorelease];
	NSString 		*format;
	
	//Perform substitutions, then escape the HTML to get it past the evil javascript guards
	newHTML = [self fillKeywords:newHTML forContent:content];
	newHTML = [self escapeString:newHTML];
	
	//Append the message to our webkit view
	if(styleVersion >= 1){
		format = AppendMessage;
	}else{
		format = AppendMessageWithScroll;
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:AppendMessage, newHTML]];
}

//
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content
{
	NSDate  *date = nil;
	NSRange	range;
	
	//date
	if([content isKindOfClass:[AIContentMessage class]]){
		date = [(AIContentMessage *)content date];
	}else if ([content isKindOfClass:[AIContentStatus class]]){
		date = [(AIContentStatus *)content date];
	}
	
	//Replacements applicable to any AIContentObject
	//	if (date){
	do{
		range = [inString rangeOfString:@"%time%"];
		if(range.location != NSNotFound){
			if(date)
				[inString replaceCharactersInRange:range withString:[timeStampFormatter stringForObjectValue:date]];
			else
				[inString deleteCharactersInRange:range];
		}
	} while(range.location != NSNotFound);
	
	//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
	do{
		range = [inString rangeOfString:@"%time{"];
		if(range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%"];
			if(endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
				if(date) {
					NSString *timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];
					
					NSDateFormatter	*dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																			 allowNaturalLanguage:NO] autorelease];
					[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
											withString:[dateFormatter stringForObjectValue:date]];						
				} else {
					[inString deleteCharactersInRange:NSUnionRange(range, endRange)];
				}
				
			}
		}
	} while(range.location != NSNotFound);
	//	}
	
	//message stuff
	if ([content isKindOfClass:[AIContentMessage class]]) {
		do{
			range = [inString rangeOfString:@"%userIconPath%"];
			if(range.location != NSNotFound){
				NSString    *userIconPath ;
				NSString	*replacementString;
				
				userIconPath = [[content source] statusObjectForKey:@"WebKitUserIconPath"];
				if (!userIconPath){
					userIconPath = [[content source] statusObjectForKey:@"UserIconPath"];
				}
					
				if (showUserIcons && userIconPath){
					replacementString = [NSString stringWithFormat:@"file://%@", userIconPath];
					
				}else{
					replacementString = ([content isOutgoing]
										 ? @"Outgoing/buddy_icon.png" 
										 : @"Incoming/buddy_icon.png");
				}
				
				[inString replaceCharactersInRange:range withString:replacementString];
			}
		} while(range.location != NSNotFound);
		
		do{
			range = [inString rangeOfString:@"%senderScreenName%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[[content source] formattedUID]];
			}
		} while(range.location != NSNotFound);
        
		do{
			range = [inString rangeOfString:@"%sender%"];
			if(range.location != NSNotFound){
				NSString		*senderDisplay = nil;
				AIListObject	*source = [content source];
				if (useCustomNameFormat){
					NSString		*displayName = [source displayName];
					NSString		*formattedUID = [source formattedUID];
					
					if (![displayName isEqualToString:formattedUID]){
						switch (nameFormat) {
							case Display_Name_Screen_Name: {
								senderDisplay = [NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID];
								break;	
							}
							case Screen_Name_Display_Name: {
								senderDisplay = [NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID];
								break;	
							}
							case Screen_Name: {
								senderDisplay = formattedUID;
								break;	
							}
						}
					}
					if (!senderDisplay){
						senderDisplay = displayName;
					}
				}else{
					senderDisplay = [source longDisplayName];
				}
				
				if ([(AIContentMessage *)content isAutoreply]){
					senderDisplay = [NSString stringWithFormat:@"%@ %@",senderDisplay,AILocalizedString(@"(Autoreply)","Short word inserted after the sender's name when displaying a message which was an autoresponse")];
				}
				
				[inString replaceCharactersInRange:range withString:senderDisplay];
			}
		} while(range.location != NSNotFound);
        
		do{
			range = [inString rangeOfString:@"%service%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[[content source] displayServiceID]];
			}
		} while(range.location != NSNotFound);	
		
		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range withString:[AIHTMLDecoder encodeHTML:[content message]
																				  headers:NO 
																				 fontTags:YES
																	   includingColorTags:allowColors
																			closeFontTags:YES
																				styleTags:YES
															   closeStyleTagsOnFontChange:YES
																		   encodeNonASCII:YES 
																			   imagesPath:@"/tmp"
																		attachmentsAsText:NO
														   attachmentImagesOnlyForSending:NO
																		   simpleTagsOnly:NO]];
		}		
		
	}else if ([content isKindOfClass:[AIContentStatus class]]) {
		do{
			range = [inString rangeOfString:@"%status%"];
			if(range.location != NSNotFound) {
				[inString replaceCharactersInRange:range withString:[(AIContentStatus *)content status]];
			}
		} while(range.location != NSNotFound);
		
		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if(range.location != NSNotFound){
			//safeString converts any attachments to text, returning an attributedString
			[inString replaceCharactersInRange:range withString:[[[content message] safeString] string]];
		}		
	}			
	
	
	return(inString);
}

- (NSMutableString *)fillKeywords:(NSMutableString *)inString
{
	NSRange	range;
	
	do{
		range = [inString rangeOfString:@"%chatName%"];
		if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range
									withString:[chat name]];
			
		}
	} while(range.location != NSNotFound);
	
	do{
		range = [inString rangeOfString:@"%incomingIconPath%"];
		if(range.location != NSNotFound){
			AIListObject	*listObject = [chat listObject];
			NSString		*iconPath = nil;
			
			if (listObject) iconPath = [listObject statusObjectForKey:@"UserIconPath"];
			
			[inString replaceCharactersInRange:range
									withString:(iconPath ? iconPath : @"incoming_icon.png")];
		}
	} while(range.location != NSNotFound);
	
	do{
		range = [inString rangeOfString:@"%outgoingIconPath%"];
		if(range.location != NSNotFound){
			AIListObject	*account = [chat account];
			NSString		*iconPath = nil;
			
			if (account) iconPath = [account statusObjectForKey:@"UserIconPath"];
			
			[inString replaceCharactersInRange:range
									withString:(iconPath ? iconPath : @"outgoing_icon.png")];
		}
	} while(range.location != NSNotFound);
	
	do{
		range = [inString rangeOfString:@"%timeOpened%"];
		if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range withString:[timeStampFormatter stringForObjectValue:[chat dateOpened]]];
		}
	} while(range.location != NSNotFound);
	
	//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
	do{
		range = [inString rangeOfString:@"%timeOpened{"];
		if(range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%"];
			if(endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
				
				NSString *timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];
				
				[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
										withString:[[[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																		   allowNaturalLanguage:NO] stringForObjectValue:[chat dateOpened]]];
				
			}
		}
	} while(range.location != NSNotFound);
	
	//Background
	{
		range = [inString rangeOfString:@"==bodyBackground=="];

		if(range.location != NSNotFound){
			NSMutableString *backgroundTag = nil;

			if (allowBackgrounds){				
				if (background || backgroundColor){
					backgroundTag = [[[NSMutableString alloc] init] autorelease];;
					if (background){
						[backgroundTag appendString:[NSString stringWithFormat:@"background: url('%@') no-repeat fixed; ",background]];
					}
					if (backgroundColor){
						[backgroundTag appendString:[NSString stringWithFormat:@"background-color: #%@; ",[backgroundColor hexString]]];
					}
				}
			}
			
			[inString replaceCharactersInRange:range
									withString:(backgroundTag ? (NSString *)backgroundTag : @"")];
		}
	}
	
	return(inString);
}
//
- (NSMutableString *)escapeString:(NSMutableString *)inString
{
	NSRange range = NSMakeRange(0, [inString length]);
	unsigned delta;
	//We need to escape a few things to get our string to the javascript without trouble
	delta = [inString replaceOccurrencesOfString:@"\\" withString:@"\\\\" 
										 options:NSLiteralSearch range:range];
	range.length += delta;
	
	delta = [inString replaceOccurrencesOfString:@"\"" withString:@"\\\"" 
						  options:NSLiteralSearch range:range];
	range.length += delta;

	delta = [inString replaceOccurrencesOfString:@"\n" withString:@"" 
										 options:NSLiteralSearch range:range];
	range.length -= delta;

	delta = [inString replaceOccurrencesOfString:@"\r" withString:@"<br />" 
										 options:NSLiteralSearch range:range];
	enum { lengthOfBRString = 6 };
	range.length += delta * lengthOfBRString;

	return(inString);
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
#pragma mark WebPolicyDelegate
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

#pragma mark WebUIDelegate
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *webViewMenuItems = [[defaultMenuItems mutableCopy] autorelease];
	AIListObject	*chatListObject = [chat listObject];
	
	NSImage *image;
	if (webViewMenuItems && (image = [element objectForKey:WebElementImageKey])){
		//Remove the first two items, which are "Open Image in New Window" and "Download Image"
		[webViewMenuItems removeObjectAtIndex:0];
		[webViewMenuItems removeObjectAtIndex:0];
		
		//XXX - Save Image As... item with the NSImage as representedObject
	}
	
	if (chatListObject){
		NSMenuItem		*menuItem;
		NSEnumerator	*enumerator;
		if (webViewMenuItems){
			//Add a separator item if items already exist in webViewMenuItems
			if ([webViewMenuItems count]){
				[webViewMenuItems addObject:[NSMenuItem separatorItem]];
			}
		}else{
			webViewMenuItems = [NSMutableArray array];
		}
		
		NSArray *locations;
		if ([chatListObject integerStatusObjectForKey:@"Stranger"]){
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_TabAction],
				[NSNumber numberWithInt:Context_Contact_Stranger_TabAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}else{
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_TabAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}
		
		NSMenu  *originalMenu = [[adium menuController] contextualMenuWithLocations:locations
																	  forListObject:chatListObject];
		
		//Have to copy and autorelease here since the itemArray will change as we go through the items
		enumerator = [[[[originalMenu itemArray] copy] autorelease] objectEnumerator];
		
		while (menuItem = [enumerator nextObject]){
			[menuItem retain];
			[originalMenu removeItem:menuItem];
			[webViewMenuItems addObject:menuItem];
			[menuItem release];
		}
	}
	
	return webViewMenuItems;
}

@end
