
#import "AIWebKitMessageViewPlugin.h"
#import "AIWebKitMessageViewController.h"

#define WEBKIT_DEFAULT_PREFS	@"WebKit Defaults"

@interface AIWebKitMessageViewPlugin (PRIVATE)
- (void)_loadAvailableWebkitStyles;
- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath;
- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content;
- (NSMutableString *)escapeString:(NSMutableString *)inString;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_flushPreferenceCache;
@end

@implementation AIWebKitMessageViewPlugin

- (void)installPlugin
{
	//Register our default preferences and install our preference view
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
    preferences = [[ESWebKitMessageViewPreferences preferencePaneForPlugin:self] retain];
	
	styleDictionary = [[NSMutableDictionary alloc] init];
	[self _loadAvailableWebkitStyles];
	
	//Observe preference changes and set our initial preferences
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	[self preferencesChanged:nil];
	
    //Register ourself as a message view plugin
    [[adium interfaceController] registerMessageViewPlugin:self];
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat withPlugin:self]);
}

#pragma mark Message substitution preferences 
//The plugin needs to know preferences which affect keyword filling
- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] == 0){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
		//Release the old preference cache
		[self _flushPreferenceCache];
		
		//Set up a time stamp format based on this user's locale
		NSString    *format = [prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT];
		
		if(!format || [format length] == 0){
			format = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO];
			[[adium preferenceController] setPreference:format
												 forKey:KEY_WEBKIT_TIME_STAMP_FORMAT
												  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		}
		
		timeStampFormatter = [[[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO] retain];
		
		showUserIcons = [[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue];
	}
}

- (void)_flushPreferenceCache
{
	[timeStampFormatter release];
}

#pragma mark Available Webkit Styles
- (void)_loadAvailableWebkitStyles
{	
	NSEnumerator	*enumerator, *fileEnumerator;
	NSString		*filePath, *resourcePath;
	NSArray			*resourcePaths;
	
	resourcePaths = [[adium resourcePathsForName:@"Message Styles"] arrayByAddingObject:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Styles"]];
	enumerator = [resourcePaths objectEnumerator];
	
    while(resourcePath = [enumerator nextObject]) {
        fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:resourcePath];
        
        //Find all the .AdiumIcon's
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:@"AdiumMessageStyle"] == 0){
                NSString		*fullPath;
                AIIconState		*previewState;
                NSBundle		*style;
				
				//Load the style and add it to our dictionary
				style = [NSBundle bundleWithPath:[resourcePath stringByAppendingPathComponent:filePath]];
				[styleDictionary setObject:style forKey:[style name]];
            }
        }
    }
}

- (NSDictionary *)availableStyleDictionary
{
	return styleDictionary;
}
- (NSBundle *)messageStyleBundleWithName:(NSString *)name
{
	return [styleDictionary objectForKey:name];
}
- (NSString *)keyForDesiredVariantOfStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Variant",desiredStyle];
}

#pragma mark Content adding

- (void)processContent:(AIContentObject *)content withPreviousContent:(AIContentObject *)previousContent forWebView:(WebView *)webView fromStylePath:(NSString *)stylePath
{
	NSString		*dateMessage = nil;
	AIContentStatus *dateSeparator = nil;
	BOOL			contentIsSimilar = NO;
	BOOL			shouldShowDateHeader = NO;

	// Should we merge consecutive messages?
	if(previousContent && [[previousContent type] compare:[content type]] == 0 && [content source] == [previousContent source]){
		contentIsSimilar = YES;
	}
	
	if ([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
		if(previousContent) {
			// Are the messages history lines from different days?
			NSCalendarDate *previousDate = [[(AIContentContext *)previousContent date] dateWithCalendarFormat:nil timeZone:nil];
			NSCalendarDate *currentDate = [[(AIContentContext *)content date] dateWithCalendarFormat:nil timeZone:nil];
			
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
			dateMessage = [NSString stringWithFormat:@"%@",[[(AIContentContext *)content date] descriptionWithCalendarFormat:@"%A, %B %d, %Y" timeZone:nil locale:nil]];
			dateSeparator = [AIContentStatus statusInChat:[content chat]
											   withSource:[[content chat] listObject]
											  destination:[[content chat] account]
													 date:[NSDate date]
												  message:dateMessage
												 withType:@"date_separator"];
			//Add the date header
			[self _addContentStatus:dateSeparator similar:NO toWebView:webView fromStylePath:stylePath];
		}
		
	}else if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0 || [[content type] compare:CONTENT_CONTEXT_TYPE] == 0){
		[self _addContentMessage:(AIContentMessage *)content 
						   similar:contentIsSimilar
						 toWebView:webView
					 fromStylePath:stylePath];
		
	}else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
		[self _addContentStatus:(AIContentStatus *)content
						  similar:contentIsSimilar
						toWebView:webView
					fromStylePath:stylePath];
	}
}

- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath
{	
	NSString		*currentStylePath;
	NSMutableString	*newHTML;
	NSString		*contentTemplate = nil;
	NSString		*nextContentTemplate = nil;
	
	//
	if([content isOutgoing]){
		currentStylePath = [stylePath stringByAppendingPathComponent:@"Outgoing"];
	}else{
		currentStylePath = [stylePath stringByAppendingPathComponent:@"Incoming"];
	}
	
	//Load context templates if appropriate
	if([[content type] compare:CONTENT_CONTEXT_TYPE] == 0) {
		contentTemplate = [NSString stringWithContentsOfFile:[currentStylePath stringByAppendingPathComponent:@"Context.html"]];
		nextContentTemplate = [NSString stringWithContentsOfFile:[currentStylePath stringByAppendingPathComponent:@"NextContext.html"]];
	}
	
	//Fall back on the content templates for normal content, or if there's no context template
	if(contentTemplate == nil)	
		contentTemplate = [NSString stringWithContentsOfFile:[currentStylePath stringByAppendingPathComponent:@"Content.html"]];
	if(nextContentTemplate == nil)
		nextContentTemplate = [NSString stringWithContentsOfFile:[currentStylePath stringByAppendingPathComponent:@"NextContent.html"]];
	
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

- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath
{
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
		
		do{
			range = [inString rangeOfString:@"%userIconPath%"];
			if(range.location != NSNotFound){
				NSString    *userIconPath = [[content source] statusObjectForKey:@"UserIconPath"];
				if (userIconPath && showUserIcons){
					[inString replaceCharactersInRange:range 
											withString:[NSString stringWithFormat:@"file://%@", userIconPath]];
				}else{
					if ([content isOutgoing]){
						[inString replaceCharactersInRange:range withString:@"Outgoing/buddy_icon.png"];
					}else{
						[inString replaceCharactersInRange:range withString:@"Incoming/buddy_icon.png"];
					}
				}
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
				[inString replaceCharactersInRange:range withString:[[content source] displayName]];
			}
		} while(range.location != NSNotFound);
        
		do{
			range = [inString rangeOfString:@"%service%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[[content source] serviceID]];
			}
		} while(range.location != NSNotFound);
		
#warning This disables any fonts in the webkit view other than what is specified by the template.
		//We don't support the message being in a content display more than once.  That would be ridiculous.
        range = [inString rangeOfString:@"%message%"];
        if(range.location != NSNotFound){
            [inString replaceCharactersInRange:range withString:[AIHTMLDecoder encodeHTML:[(AIContentMessage *)content message]
																				  headers:NO 
																				 fontTags:NO
																			closeFontTags:NO
																				styleTags:YES   
															   closeStyleTagsOnFontChange:NO
																		   encodeNonASCII:YES 
																			   imagesPath:@"/tmp"
																		attachmentsAsText:NO]];
        }
	
		do{
			range = [inString rangeOfString:@"%time%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[timeStampFormatter stringForObjectValue:[(AIContentMessage *)content date]]];
			}
		} while(range.location != NSNotFound);
		
		//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
		do{
			range = [inString rangeOfString:@"%time{"];
			if(range.location != NSNotFound) {
				NSRange endRange;
				endRange = [inString rangeOfString:@"}%"];
				if(endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
					
					NSString *timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];
					
					[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
											withString:[[[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																			   allowNaturalLanguage:NO] stringForObjectValue:[(AIContentMessage *)content date]]];
					
				}
			}
		} while(range.location != NSNotFound);
		
	}else if ([content isKindOfClass:[AIContentStatus class]]) {
		
		do{
			range = [inString rangeOfString:@"%message%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[(AIContentStatus *)content message]];
			}
		} while(range.location != NSNotFound);
		
		do{
			range = [inString rangeOfString:@"%time%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range
										withString:[timeStampFormatter stringForObjectValue:[(AIContentStatus *)content date]]];
			}
		} while(range.location != NSNotFound);
		
		do{
			range = [inString rangeOfString:@"%status%"];
			if(range.location != NSNotFound) {
				[inString replaceCharactersInRange:range withString:[(AIContentStatus *)content status]];
			}
		} while(range.location != NSNotFound);
		
		//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
		do{
			range = [inString rangeOfString:@"%time{"];
			if(range.location != NSNotFound) {
				NSRange endRange;
				endRange = [inString rangeOfString:@"}%"];
				if(endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
					
					NSString *timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];
					
					[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
											withString:[[[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																			   allowNaturalLanguage:NO] stringForObjectValue:[(AIContentMessage *)content date]]];
					
				}
			}
		} while(range.location != NSNotFound);
		
	}
	
	return(inString);
}

//
- (NSMutableString *)escapeString:(NSMutableString *)inString
{
	//We need to escape a few things to get our string to the javascript without trouble
	[inString replaceOccurrencesOfString:@"\\" withString:@"\\\\" 
								 options:NSLiteralSearch range:NSMakeRange(0,[inString length])];
	
	[inString replaceOccurrencesOfString:@"\"" withString:@"\\\"" 
						  options:NSLiteralSearch range:NSMakeRange(0,[inString length])];

	[inString replaceOccurrencesOfString:@"\n" withString:@"" 
								 options:NSLiteralSearch range:NSMakeRange(0,[inString length])];

	[inString replaceOccurrencesOfString:@"\r" withString:@"<br />" 
								 options:NSLiteralSearch range:NSMakeRange(0,[inString length])];
	return(inString);
}

@end
