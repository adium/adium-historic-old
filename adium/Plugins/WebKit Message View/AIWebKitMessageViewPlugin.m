
#import "AIWebKitMessageViewPlugin.h"
#import "AIWebKitMessageViewController.h"



@interface AIWebKitMessageViewPlugin (PRIVATE)
- (void)_scanAvailableWebkitStyles;
- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath allowingColors:(BOOL)allowColors;
- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content allowingColors:(BOOL)allowColors;
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forStyle:(NSBundle *)style variant:(NSString *)variant forChat:(AIChat *)chat;
- (NSMutableString *)escapeString:(NSMutableString *)inString;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName;
- (void)_flushPreferenceCache;
@end

@implementation AIWebKitMessageViewPlugin

DeclareString(AppendMessageWithScroll);
DeclareString(AppendNextMessageWithScroll);
DeclareString(AppendMessage);
DeclareString(AppendNextMessage);

- (void)installPlugin
{
	
	if([NSApp isOnPantherOrBetter]){
#warning --willmove--
		InitString(AppendMessageWithScroll,@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();");
		InitString(AppendNextMessageWithScroll,@"checkIfScrollToBottomIsNeeded(); appendNextMessage(\"%@\"); scrollToBottomIfNeeded();");
		InitString(AppendMessage,@"appendMessage(\"%@\");");
		InitString(AppendNextMessage,@"appendNextMessage(\"%@\");");
		//Observe preference changes and set our initial preferences
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(preferencesChanged:)
										   name:Preference_GroupChanged
										 object:nil];
		[self preferencesChanged:nil];
#warning --willmove--
		
		//Init

		styleDictionary = nil;
		[self _scanAvailableWebkitStyles];
		
		//Setup our preferences
		
		[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]]
											  forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		preferences = [[ESWebKitMessageViewPreferences preferencePaneForPlugin:self] retain];
		advancedPreferences = [[ESWKMVAdvancedPreferences preferencePaneForPlugin:self] retain];
		
		//Observe for installation of new styles
		[[adium notificationCenter] addObserver:self
									   selector:@selector(stylesChanged:)
										   name:Adium_Xtras_Changed
										 object:nil];
		
		//Register ourself as a message view plugin
		[[adium interfaceController] registerMessageViewPlugin:self];
	}

	[adium createResourcePathForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
	 
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat withPlugin:self]);
}


//Available Webkit Styles ----------------------------------------------------------------------------------------------
#pragma mark Available Webkit Styles
//Scan for available webkit styles (Call before trying to load/access a style)
- (void)_scanAvailableWebkitStyles
{	
	NSEnumerator	*enumerator, *fileEnumerator;
	NSString		*filePath, *resourcePath;
	NSArray			*resourcePaths;
	
	//Clear the current dictionary of styles and ready a new mutable dictionary
	[styleDictionary release];
	styleDictionary = [[NSMutableDictionary alloc] init];
	
	//Get all resource paths to search
	resourcePaths = [[adium resourcePathsForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT] arrayByAddingObject:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Styles"]];
	enumerator = [resourcePaths objectEnumerator];
	
	NSString	*AdiumMessageStyle = @"AdiumMessageStyle";
    while(resourcePath = [enumerator nextObject]) {
        fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:resourcePath];
        
        //Find all the message styles
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:AdiumMessageStyle] == 0){
                NSString		*fullPath;
                AIIconState		*previewState;
                NSBundle		*style;
#warning --store strings, not bundles--
				//Load the style and add it to our dictionary
				style = [NSBundle bundleWithPath:[resourcePath stringByAppendingPathComponent:filePath]];
				if(style){
					NSString	*styleName = [style name];
					if(styleName && [styleName length]) [styleDictionary setObject:style forKey:styleName];
				}
            }
        }
    }
}

//Returns a dictionary of available style identifiers and their paths
//- (NSDictionary *)availableStyles
- (NSDictionary *)availableStyleDictionary
{
	return(styleDictionary);
}

//Fetch the bundle for a message style by its bundle identifier
//- (NSBundle *)messageStyleBundleWithIdentifier:(NSString *)name
//{
//	return([NSBundle bundleWithPath:[styleDictionary objectForKey:name]]);
//}
- (NSBundle *)messageStyleBundleWithName:(NSString *)name
{
	return([styleDictionary objectForKey:name]);
}

//The default message style bundle
//- (NSBundle *)defaultMessageStyleBundle
//{
//	return([self messageStyleBundleWithIdentifier:MESSAGE_DEFAULT_STYLE]);
//}

//If the styles have changed, rebuild our list of available styles
- (void)stylesChanged:(NSNotification *)notification
{
	[self _scanAvailableWebkitStyles];
}























#pragma mark Message substitution preferences 
//The plugin needs to know preferences which affect keyword filling
- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY]){
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
		
		timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO];
		
		showUserIcons = [[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue];
		useCustomNameFormat = [[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue];
		nameFormat = [[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue];
		combineConsecutive = [[prefDict objectForKey:KEY_WEBKIT_COMBINE_CONSECUTIVE] boolValue];
	}
}

- (void)_flushPreferenceCache
{
	[timeStampFormatter release];
}

- (void)_loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName
{
	NSString	*prefIdentifier = [NSString stringWithFormat:@"Adium Style %@ Preferences",styleName];
	[webView setPreferencesIdentifier:prefIdentifier];
	[[webView preferences] setAutosaves:YES];

	if (![[[adium preferenceController] preferenceForKey:prefIdentifier
												   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] boolValue]){
		
		//Load defaults from the bundle or our defaults, as appropriate
		NSBundle	*style = [self messageStyleBundleWithName:styleName];

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

#pragma mark Available Webkit Styles

- (NSString *)variantKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Variant",desiredStyle];
}
- (NSString *)backgroundKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Background",desiredStyle];	
}
- (NSString *)backgroundColorKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Background Color",desiredStyle];
}

- (BOOL)boolForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant boolDefault:(BOOL)defaultValue
{
	NSNumber	*value = [style objectForInfoDictionaryKey:[NSString stringWithFormat:@"%@:%@",key,variant]];
	if (!value){
		value = [style objectForInfoDictionaryKey:key];
	}
	return (value ? [value boolValue] : defaultValue);
}


- (void)loadStyle:(NSBundle *)style withName:(NSString *)styleName variant:(NSString *)variant withCSS:(NSString *)CSS forChat:(AIChat *)chat intoWebView:(ESWebView *)webView
{
	NSString		*headerHTML, *footerHTML;
	NSMutableString *templateHTML;
	NSString		*stylePath = [style resourcePath];
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
	templateHTML = [self fillKeywords:templateHTML forStyle:style variant:variant forChat:chat];

	//Load the style's preferences
	[self _loadPreferencesForWebView:webView withStyleNamed:styleName];
		
	//Feed it to the webview
	[[webView mainFrame] loadHTMLString:templateHTML baseURL:nil];
}


#pragma mark Content adding

- (void)processContent:(AIContentObject *)content withPreviousContent:(AIContentObject *)previousContent forWebView:(WebView *)webView fromStylePath:(NSString *)stylePath allowingColors:(BOOL)allowColors
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
			[self _addContentStatus:dateSeparator similar:NO toWebView:webView fromStylePath:stylePath];
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
			[self _addContentStatus:dateSeparator similar:NO toWebView:webView fromStylePath:stylePath];
		
		}
	}
		
	if([[content type] isEqualToString:CONTENT_MESSAGE_TYPE] || [[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
		[self _addContentMessage:(AIContentMessage *)content 
						   similar:contentIsSimilar
						 toWebView:webView
					 fromStylePath:stylePath
				  allowingColors:allowColors];
		
	}else if([[content type] isEqualToString:CONTENT_STATUS_TYPE]){
		[self _addContentStatus:(AIContentStatus *)content
						  similar:contentIsSimilar
						toWebView:webView
					fromStylePath:stylePath];
	}
}

- (void)_addContentMessage:(AIContentMessage *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath allowingColors:(BOOL)allowColors
{	
	NSString		*currentStylePath;
	NSMutableString	*newHTML = nil;
	NSString		*templateFile;
	BOOL			isContext = [[content type] isEqualToString:CONTENT_CONTEXT_TYPE];

	//Disable color for context
	if(isContext) allowColors = NO;
	
	//
	currentStylePath = [stylePath stringByAppendingPathComponent:([content isOutgoing] ? @"Outgoing" : @"Incoming")];
	
	//Load context templates if appropriate
	if (contentIsSimilar && combineConsecutive){
		templateFile = (isContext ? @"NextContext.html" : @"NextContent.html");
	}else{
		templateFile = (isContext ? @"Context.html" : @"Content.html");
	}
	
	newHTML = [NSMutableString stringWithContentsOfFile:[currentStylePath stringByAppendingPathComponent:templateFile]];
	
	//Fall back on the content files if context files were desired and not present
	if (!newHTML){
		if (contentIsSimilar && combineConsecutive){
			templateFile = @"NextContent.html";
		}else{
			templateFile = @"Content.html";
		}
		
		newHTML = [NSMutableString stringWithContentsOfFile:[currentStylePath stringByAppendingPathComponent:templateFile]];
	}

	//Perform substitutions, then escape the HTML to get it past the evil javascript guards
	newHTML = [self fillKeywords:newHTML forContent:content allowingColors:allowColors];
	newHTML = [self escapeString:newHTML];

	NSString *format;
	if(styleVersion >= 1){
		format = contentIsSimilar ? AppendNextMessage : AppendMessage;
	}else{
		format = contentIsSimilar ? AppendNextMessageWithScroll : AppendMessageWithScroll;
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:format, newHTML]];
}
	
- (void)_addContentStatus:(AIContentStatus *)content similar:(BOOL)contentIsSimilar toWebView:(WebView *)webView fromStylePath:(NSString *)stylePath
{
    NSMutableString *newHTML = [NSMutableString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Status.html"]];
	NSString 		*format;
	
	//Perform substitutions, then escape the HTML to get it past the evil javascript guards
	newHTML = [self fillKeywords:newHTML forContent:content allowingColors:YES];
	newHTML = [self escapeString:newHTML];

	if(styleVersion >= 1){
		format = AppendMessage;
	}else{
		format = AppendMessageWithScroll;
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:AppendMessage, newHTML]];
}

//
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content allowingColors:(BOOL)allowColors
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
				
				if (showUserIcons && (userIconPath = [[content source] statusObjectForKey:@"UserIconPath"])){
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
	}
	
	
		//message (must do last)
		if ([content isKindOfClass:[AIContentMessage class]]) {
			range = [inString rangeOfString:@"%message%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[AIHTMLDecoder encodeHTML:[(AIContentMessage *)content message]
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
				range = [inString rangeOfString:@"%message%"];
				if(range.location != NSNotFound){
					[inString replaceCharactersInRange:range withString:[[(AIContentStatus *)content message] string]];
				}
			} while(range.location != NSNotFound);
			
			do{
				range = [inString rangeOfString:@"%status%"];
				if(range.location != NSNotFound) {
					[inString replaceCharactersInRange:range withString:[(AIContentStatus *)content status]];
				}
			} while(range.location != NSNotFound);
		}			
		
		
	return(inString);
}

- (NSMutableString *)fillKeywords:(NSMutableString *)inString forStyle:(NSBundle *)style variant:(NSString *)variant forChat:(AIChat *)chat
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
			BOOL disableCustomBackground = [self boolForKey:@"DisableCustomBackground"
													  style:style 
													variant:variant
												boolDefault:NO];
			NSMutableString *backgroundTag = nil;

			if (!disableCustomBackground){
				NSString	*background = [[adium preferenceController] preferenceForKey:[self backgroundKeyForStyle:[style name]]
																				   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
				NSColor		*backgroundColor = [[[adium preferenceController] preferenceForKey:[self backgroundColorKeyForStyle:[style name]]
																						 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] representedColor];
				
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
