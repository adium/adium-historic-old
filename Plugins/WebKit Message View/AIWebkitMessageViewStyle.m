/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIWebkitMessageViewStyle.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/ESDateFormatterAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>

//
#define LEGACY_VERSION_THRESHOLD		3	//Styles older than this version are considered legacy

//
#define KEY_WEBKIT_VERSION				@"MessageViewVersion"

@interface AIWebkitMessageViewStyle (PRIVATE)
- (id)initWithBundle:(NSBundle *)inBundle;
- (void)_loadTemplates;
- (NSMutableString *)_escapeStringForPassingToScript:(NSMutableString *)inString;
- (NSString *)noVariantName;
@end

//Cached BOM scripts for appending content
DeclareString(AppendMessageWithScroll);
DeclareString(AppendNextMessageWithScroll);
DeclareString(AppendMessage);
DeclareString(AppendNextMessage);

@implementation AIWebkitMessageViewStyle

/*!
 * @brief Create a message view style instance for the passed style bundle
 */
+ (id)messageViewStyleFromBundle:(NSBundle *)inBundle
{
	return([[[self alloc] initWithBundle:inBundle] autorelease]);
}

/*!
 * @brief Initialize
 */
- (id)initWithBundle:(NSBundle *)inBundle
{
	//Init
	[super init];
	styleBundle = [inBundle retain];
	stylePath = [[styleBundle resourcePath] retain];

	//Default behavior
	allowTextBackgrounds = YES;
	
	//Prepare our append content BOM scripts.  These are shared between all AIWebkitMessageViewStyle instances.
	if(!AppendMessageWithScroll){
		InitString(AppendMessageWithScroll,@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();");
		InitString(AppendNextMessageWithScroll,@"checkIfScrollToBottomIsNeeded(); appendNextMessage(\"%@\"); scrollToBottomIfNeeded();");
		InitString(AppendMessage,@"appendMessage(\"%@\");");
		InitString(AppendNextMessage,@"appendNextMessage(\"%@\");");
	}
	
	//Our styles are versioned so we can change how they work without breaking compatability
	/*
	 Version 0: Initial Webkit Version
	 Version 1: Template.html now handles all scroll-to-bottom functionality.  It is no longer required to call the
	 scrollToBottom functions when inserting content.
	 Version 2: No signigifant changes
	 Version 3: main.css is no longer a separate style, default style a separate file in /variants like all others
	 */
	styleVersion = [[styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_VERSION] intValue];

	//Pre-fetch our templates
	[self _loadTemplates];
	
	//Style flags
	allowsCustomBackground = ![[styleBundle objectForInfoDictionaryKey:@"DisableCustomBackground"] boolValue];
	combineConsecutive = ![[styleBundle objectForInfoDictionaryKey:@"DisableCombineConsecutive"] boolValue];
	//allowsTextColors = ![[styleBundle objectForInfoDictionaryKey:@"AllowTextColors"] boolValue];		

	return(self);
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{	
	//Templates
	[contentInHTML release];
	[nextContentInHTML release];
	[contentOutHTML release];
	[nextContentOutHTML release];
	[contextInHTML release];
	[nextContextInHTML release];
	[contextOutHTML release];
	[nextContextOutHTML release];
	[statusHTML release];	
	[baseHTML release];
	
	[super dealloc];
}

/*!
 * Returns YES if this style is considered legacy
 *
 * Legacy/outdated styles may perform sub-optimally because they lack beneficial changes made in modern styles.
 */
- (BOOL)isLegacy
{
	return(styleVersion < LEGACY_VERSION_THRESHOLD);
}


//Settings -------------------------------------------------------------------------------------------------------------
#pragma mark Settings
/*!
 * @brief Style supports custom backgrounds
 */
- (BOOL)allowsCustomBackground
{
	return(allowsCustomBackground);
}

/*!
 * @brief Style's default font family
 */
- (NSString *)defaultFontFamily
{
	return([styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_FAMILY]);
}

/*!
 * @brief Style's default font size
 */
- (NSNumber *)defaultFontSize
{
	return([styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_SIZE]);
}

/*!
 * @brief Style's has a header
 */
- (BOOL)hasHeader
{
	return(headerHTML && [headerHTML length]);
}


//Behavior -------------------------------------------------------------------------------------------------------------
#pragma mark Behavior
/*!
 * @brief Set format of dates/time stamps
 */
- (void)setDateFormat:(NSString *)format
{
	if(!format || [format length] == 0){
		format = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO];
	}
	[timeStampFormatter release];
	timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO];
}

/*!
 * @brief Set visibility of user icons
 */
- (void)setShowUserIcons:(BOOL)inValue
{
	showUserIcons = inValue;
}

/*!
 * @brief Set visibility of header
 */
- (void)setShowHeader:(BOOL)inValue
{
	showHeader = inValue;
}

/*!
 * @brief Toggle use of a custom name format
 */
- (void)setUseCustomNameFormat:(BOOL)inValue
{
	useCustomNameFormat = inValue;
}

/*!
 * @brief Set the custom name format being used
 */
- (void)setNameFormat:(int)inValue
{
	nameFormat = inValue;
}

/*!
 * @brief Set visibility of message background colors
 */
- (void)setAllowTextBackgrounds:(BOOL)inValue
{
	allowTextBackgrounds = inValue;
}

/*!
 * @brief Set the custom background image
 */
- (void)setCustomBackgroundPath:(NSString *)inPath
{
	if(customBackgroundPath != inPath){
		[customBackgroundPath release];
		customBackgroundPath = [inPath retain];
	}
}

/*!
 * @brief Set the custom background image type (How it is displayed - stretched, tiled, centered, etc)
 */
- (void)setCustomBackgroundType:(AIWebkitBackgroundType)inType
{
	customBackgroundType = inType;
}

/*!
 * @brief Set the custom background color
 */
- (void)setCustomBackgroundColor:(NSColor *)inColor
{
	if(customBackgroundColor != inColor){
		[customBackgroundColor release];
		customBackgroundColor = [inColor retain];
	}
}

/*!
 * @brief Toggle visibility of received coloring
 */
- (void)setShowIncomingMessageColors:(BOOL)inValue
{
	showIncomingColors = inValue;
}

/*!
 * @brief Toggle visibility of received fonts
 */
- (void)setShowIncomingMessageFonts:(BOOL)inValue
{
	showIncomingFonts = inValue;
}


//Templates ------------------------------------------------------------------------------------------------------------
#pragma mark Templates
/*!
 * @brief Returns the base template for this style
 *
 * The base template is basically the empty view, and serves as the starting point of all content insertion.
 */
- (NSString *)baseTemplateWithVariant:(NSString *)variant chat:(AIChat *)chat
{
	NSMutableString	*templateHTML = [NSMutableString stringWithFormat:baseHTML,		//Template
		[[NSURL fileURLWithPath:stylePath] absoluteString],							//Base path
		[self pathForVariant:variant],												//Variant path
		(showHeader ? headerHTML : @""),
		footerHTML];

	return([self fillKeywordsForBaseTemplate:templateHTML chat:chat]);
}

/*!
 * @brief Returns the template for inserting content
 * 
 * Templates may be different for different content types and for content objects similar to the one preceding them.
 */
- (NSString *)templateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar
{
	NSString	*template;
	
	//Get the correct template for what we're inserting
	if([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]){
		if([content isOutgoing]){
			template = (contentIsSimilar ? nextContentOutHTML : contentOutHTML);
		}else{
			template = (contentIsSimilar ? nextContentInHTML : contentInHTML);
		}
	
	}else if([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
		if([content isOutgoing]){
			template = (contentIsSimilar ? nextContextOutHTML : contextOutHTML);
		}else{
			template = (contentIsSimilar ? nextContextInHTML : contextInHTML);
		}

	}else{
		template = statusHTML;
	
	}
	
	return(template);
}

/*!
 * @brief Pre-fetch all the style templates
 *
 * This needs to be called before either baseTemplate or templateForContent is called
 */
- (void)_loadTemplates
{		
	//Load the style's templates
	//We can't use NSString's initWithContentsOfFile here.  HTML files are interpreted in the defaultCEncoding
	//(which varies by system) when read that way.  We want to always interpret the files as ASCII.
	headerHTML = [[NSString stringWithContentsOfASCIIFile:[stylePath stringByAppendingPathComponent:@"Header.html"]] retain];
	footerHTML = [[NSString stringWithContentsOfASCIIFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]] retain];
	baseHTML = [NSString stringWithContentsOfASCIIFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
	
	//Starting with version 1, styles can choose to not include template.html.  If the template is not included 
	//Adium's default will be used.  This is preferred since any future template updates will apply to the style
	if((!baseHTML || [baseHTML length] == 0) && styleVersion >= 1){		
		baseHTML = [NSString stringWithContentsOfASCIIFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Template" ofType:@"html"]];
	}
	[baseHTML retain];	
	
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


//Scripts --------------------------------------------------------------------------------------------------------------
#pragma mark Scripts
/*!
 * @brief Returns the BOM script for appending content
 */
- (NSString *)scriptForAppendingContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar
{
	NSMutableString	*newHTML;
	NSString		*script;
	
	//If combining of consecutive messages has been disabled, we treat all content as non-similar
	if(!combineConsecutive) contentIsSimilar = NO;
	
	//Fetch the correct template and substitute keywords for the passed content
	newHTML = [[[self templateForContent:content similar:contentIsSimilar] mutableCopy] autorelease];
	newHTML = [self fillKeywords:newHTML forContent:content];
	
	//BOM scripts vary by style version
	if(styleVersion >= 1){
		script = (contentIsSimilar ? AppendNextMessage : AppendMessage);
	}else{
		script = (contentIsSimilar ? AppendNextMessageWithScroll : AppendMessageWithScroll);
	}
	
	return([NSString stringWithFormat:script, [self _escapeStringForPassingToScript:newHTML]]); 
}

/*!
 * @brief Returns the BOM script for changing the view's variant
 */
- (NSString *)scriptForChangingVariant:(NSString *)variant
{
	return([NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");",[self pathForVariant:variant]]);
}

/*!
 * @brief Escape a string for passing to our BOM scripts
 */
- (NSMutableString *)_escapeStringForPassingToScript:(NSMutableString *)inString
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


//Variants -------------------------------------------------------------------------------------------------------------
#pragma mark Variants
/*!
 * @brief Returns an alphabetized array of available variant names for this style
 */
- (NSArray *)availableVariants
{
	NSMutableArray	*availableVariants = [NSMutableArray array];
	NSEnumerator	*enumerator = [[styleBundle pathsForResourcesOfType:@"css" inDirectory:@"Variants"] objectEnumerator];
	NSString		*path;
	
	//Build an array of all variant names
	while(path = [enumerator nextObject]){
		[availableVariants addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
	}

	//Style versions before 3 stored the default variant in a separate location.  They also allowed for this
	//varient name to not be specified, and would substitute a localized string in its place.
	if(styleVersion < 3){
		[availableVariants addObject:[self noVariantName]];
	}
	
	//Alphabetize the variants
	[availableVariants sortUsingSelector:@selector(compare:)];
	
	return(availableVariants);
}

/*!
 * @brief Returns the file path to the css file defining a variant of this style
 */
- (NSString *)pathForVariant:(NSString *)variant
{
	//Styles before version 3 stored the default variant in main.css, and not in the variants folder.
	if(styleVersion < 3 && [variant isEqualToString:[self noVariantName]]){
		return(@"main.css");
	}else{
		return([NSString stringWithFormat:@"Variants/%@.css",variant]);
	}
}

/*!
 * @brief Base variant name for styles before version 2
 */
- (NSString *)noVariantName
{
	NSString	*noVariantName = [styleBundle objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
	return(noVariantName ? noVariantName : AILocalizedString(@"Normal","Normal style variant menu item"));
}

/*!
 * @brief Default variant for styles version 3 and later
 */
- (NSString *)defaultVariant
{
	return([styleBundle objectForInfoDictionaryKey:@"DefaultVariant"]);
}


//Keyword Replacement --------------------------------------------------------------------------------------------------
#pragma mark Keyword replacement
/*!
 * @brief Substitute content keywords
 *
 * Substitute keywords in a template with the appropriate values for the passed content object
 * We allow the message style to handle this since the behavior of keywords is dependent on the style and may change
 * for future style versions
 */
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content
{
	NSDate			*date = nil;
	NSRange			range;
		
	//date
	if([content isKindOfClass:[AIContentMessage class]]){
		date = [(AIContentMessage *)content date];
	}else if([content isKindOfClass:[AIContentStatus class]]){
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
		
		AIListObject	*contentSource = [content source];
		
		do{
			range = [inString rangeOfString:@"%userIconPath%"];
			if(range.location != NSNotFound){
				NSString    *userIconPath ;
				NSString	*replacementString;
				
				userIconPath = [contentSource statusObjectForKey:KEY_WEBKIT_USER_ICON];
				if (!userIconPath){
					userIconPath = [contentSource statusObjectForKey:@"UserIconPath"];
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
				NSString *formattedUID = [contentSource formattedUID];
				[inString replaceCharactersInRange:range withString:[(formattedUID ? formattedUID : [contentSource displayName]) stringByEscapingForHTML]];
			}
		} while(range.location != NSNotFound);
        
		do{
			range = [inString rangeOfString:@"%sender%"];
			if(range.location != NSNotFound){
				NSString		*senderDisplay = nil;
				if (useCustomNameFormat){
					NSString		*displayName = [contentSource displayName];
					NSString		*formattedUID = [contentSource formattedUID];
					
					if (formattedUID && ![displayName isEqualToString:formattedUID]){
						switch (nameFormat) {
							case Display_Name_Screen_Name: {
								senderDisplay = [NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID];
								break;	
							}
							case Screen_Name_Display_Name: {
								senderDisplay = [NSString stringWithFormat:@"%@ (%@)",formattedUID,displayName];
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
					senderDisplay = [contentSource longDisplayName];
				}
				
				if ([(AIContentMessage *)content isAutoreply]){
					senderDisplay = [NSString stringWithFormat:@"%@ %@",senderDisplay,AILocalizedString(@"(Autoreply)","Short word inserted after the sender's name when displaying a message which was an autoresponse")];
				}
					
				[inString replaceCharactersInRange:range withString:[senderDisplay stringByEscapingForHTML]];
			}
		} while(range.location != NSNotFound);
        
		do{
			range = [inString rangeOfString:@"%service%"];
			if(range.location != NSNotFound){
				[inString replaceCharactersInRange:range withString:[[contentSource service] shortDescription]];
			}
		} while(range.location != NSNotFound);	

		//Blatantly stealing the date code for the background color script.
		do{
			range = [inString rangeOfString:@"%textbackgroundcolor{"];
			if(range.location != NSNotFound) {
				NSRange endRange;
				endRange = [inString rangeOfString:@"}%"];
				if(endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
					NSString *transparency = [inString substringWithRange:NSMakeRange(NSMaxRange(range),
																					  (endRange.location - NSMaxRange(range)))];
					
					if(allowTextBackgrounds && showIncomingColors){
						NSString *thisIsATemporaryString;
						unsigned int rgb = 0, red, green, blue;
						NSScanner *hexcode;
						thisIsATemporaryString = [AIHTMLDecoder encodeHTML:[content message] headers:NO 
																  fontTags:NO
														includingColorTags:NO
															 closeFontTags:NO
																 styleTags:NO
												closeStyleTagsOnFontChange:NO
															encodeNonASCII:NO
															  encodeSpaces:NO
																imagesPath:@"/tmp"
														 attachmentsAsText:NO
											attachmentImagesOnlyForSending:NO
															simpleTagsOnly:NO
															bodyBackground:YES];
						hexcode = [NSScanner scannerWithString:thisIsATemporaryString];
						[hexcode  scanHexInt:&rgb];
						if(![thisIsATemporaryString length] && rgb == 0){
							[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:@""];
						}else{
							red = (rgb & 0xff0000) >> 16;
							green = (rgb & 0x00ff00) >> 8;
							blue = rgb & 0x0000ff;
							[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:[NSString stringWithFormat:@"rgba(%d, %d, %d, %@)", red, green, blue, transparency]];
						}
					}else{
						[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:@""];
					}
				}else if(endRange.location == NSMaxRange(range)){
					if(allowTextBackgrounds && showIncomingColors){
						NSString *thisIsATemporaryString;
						
						thisIsATemporaryString = [AIHTMLDecoder encodeHTML:[content message] headers:NO 
																  fontTags:NO
														includingColorTags:NO
															 closeFontTags:NO
																 styleTags:NO
												closeStyleTagsOnFontChange:NO
															encodeNonASCII:NO
															  encodeSpaces:NO
																imagesPath:@"/tmp"
														 attachmentsAsText:NO
											attachmentImagesOnlyForSending:NO
															simpleTagsOnly:NO
															bodyBackground:YES];
						[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:[NSString stringWithFormat:@"#%@", thisIsATemporaryString]];
					}else{
						[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:@""];
					}	
				}
			}
		} while(range.location != NSNotFound);
		
		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range withString:[AIHTMLDecoder encodeHTML:[content message]
																				  headers:NO 
																				 fontTags:([content isOutgoing] ? YES : showIncomingFonts)
																	   includingColorTags:([content isOutgoing] ? YES : showIncomingColors)
																			closeFontTags:YES
																				styleTags:YES
															   closeStyleTagsOnFontChange:YES
																		   encodeNonASCII:YES
																			 encodeSpaces:YES
																			   imagesPath:@"/tmp"
																		attachmentsAsText:NO
														   attachmentImagesOnlyForSending:NO
																		   simpleTagsOnly:NO
																		   bodyBackground:NO]];
		}
		
	}else if ([content isKindOfClass:[AIContentStatus class]]) {
		do{
			range = [inString rangeOfString:@"%status%"];
			if(range.location != NSNotFound) {
				[inString replaceCharactersInRange:range withString:[[(AIContentStatus *)content status] stringByEscapingForHTML]];
			}
		} while(range.location != NSNotFound);
		
		
		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if(range.location != NSNotFound){
			if(allowTextBackgrounds && showIncomingColors){
				[inString replaceCharactersInRange:range withString:[AIHTMLDecoder encodeHTML:[content message]
																					  headers:NO 
																					 fontTags:NO
																		   includingColorTags:YES
																				closeFontTags:YES
																					styleTags:NO
																   closeStyleTagsOnFontChange:YES
																			   encodeNonASCII:YES
																				 encodeSpaces:YES
																				   imagesPath:@"/tmp"
																			attachmentsAsText:NO
															   attachmentImagesOnlyForSending:NO
																			   simpleTagsOnly:NO
																			   bodyBackground:NO]];
			}else{
				[inString replaceCharactersInRange:range withString:[AIHTMLDecoder encodeHTML:[content message]
																					  headers:NO 
																					 fontTags:NO
																		   includingColorTags:YES
																				closeFontTags:YES
																					styleTags:NO
																   closeStyleTagsOnFontChange:YES
																			   encodeNonASCII:YES
																				 encodeSpaces:YES
																				   imagesPath:@"/tmp"
																			attachmentsAsText:NO
															   attachmentImagesOnlyForSending:NO
																			   simpleTagsOnly:NO
																			   bodyBackground:NO]];
			}
		}
	}

	return(inString);
}

/*!
 * @brief Substitute base keywords
 *
 * We allow the message style to handle this since the behavior of keywords is dependent on the style and may change
 * for future style versions
 */
- (NSMutableString *)fillKeywordsForBaseTemplate:(NSMutableString *)inString chat:(AIChat *)chat
{
	NSRange	range;
	
	do{
		range = [inString rangeOfString:@"%chatName%"];
		if(range.location != NSNotFound){
			[inString replaceCharactersInRange:range
									withString:[[chat displayName] stringByEscapingForHTML]];
			
		}
	} while(range.location != NSNotFound);
	
	do{
		range = [inString rangeOfString:@"%incomingIconPath%"];
		if(range.location != NSNotFound){
			AIListContact	*listObject = [chat listObject];
			NSString		*iconPath = nil;
			
			if (listObject){
				iconPath = [listObject statusObjectForKey:KEY_WEBKIT_USER_ICON];
				if (!iconPath){
					iconPath = [listObject statusObjectForKey:@"UserIconPath"];
				}
			}
						
			[inString replaceCharactersInRange:range
									withString:(iconPath ? iconPath : @"incoming_icon.png")];
		}
	} while(range.location != NSNotFound);
	
	do{
		range = [inString rangeOfString:@"%outgoingIconPath%"];
		if(range.location != NSNotFound){
			AIListObject	*account = [chat account];
			NSString		*iconPath = nil;
			
			if (account){
				iconPath = [account statusObjectForKey:KEY_WEBKIT_USER_ICON];
				if (!iconPath){
					iconPath = [account statusObjectForKey:@"UserIconPath"];
				}
			}
			
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
				NSDateFormatter	*dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																		 allowNaturalLanguage:NO] autorelease];
				
				[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
										withString:[dateFormatter stringForObjectValue:[chat dateOpened]]];
				
			}
		}
	} while(range.location != NSNotFound);
	
	//Background
	{
		range = [inString rangeOfString:@"==bodyBackground=="];
		
		if(range.location != NSNotFound){ //a backgroundImage tag is not required
			NSMutableString *bodyTag = nil;

			if(allowsCustomBackground && (customBackgroundPath || customBackgroundColor)){				
				bodyTag = [[[NSMutableString alloc] init] autorelease];
				
				if(customBackgroundPath){
					if([customBackgroundPath length]){
						switch(customBackgroundType){
							case BackgroundNormal:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-repeat: no-repeat; background-attachment:fixed;", customBackgroundPath]];
							break;
							case BackgroundCenter:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-position: center; background-repeat: no-repeat; background-attachment:fixed;", customBackgroundPath]];
							break;
							case BackgroundTile:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-repeat: repeat;", customBackgroundPath]];
							break;
						}
					}else{
						[bodyTag appendString:@"background-image: none; "];
					}
				}
				if(customBackgroundColor){
					[bodyTag appendString:[NSString stringWithFormat:@"background-color: #%@; ", [customBackgroundColor hexString]]];
				}
 			}
 		}
 	}

	return(inString);
}

@end
