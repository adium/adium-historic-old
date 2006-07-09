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
#import <AIUtilities/AIDateFormatterAdditions.h>
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
#import <Adium/ESFileTransfer.h>

//
#define LEGACY_VERSION_THRESHOLD		3	//Styles older than this version are considered legacy

//
#define KEY_WEBKIT_VERSION				@"MessageViewVersion"

//BOM scripts for appending content.
#define APPEND_MESSAGE_WITH_SCROLL		@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();"
#define APPEND_NEXT_MESSAGE_WITH_SCROLL	@"checkIfScrollToBottomIsNeeded(); appendNextMessage(\"%@\"); scrollToBottomIfNeeded();"
#define APPEND_MESSAGE					@"appendMessage(\"%@\");"
#define APPEND_NEXT_MESSAGE				@"appendNextMessage(\"%@\");"
#define APPEND_MESSAGE_NO_SCROLL		@"appendMessageNoScroll(\"%@\");"
#define	APPEND_NEXT_MESSAGE_NO_SCROLL	@"appendNextMessageNoScroll(\"%@\");"

#define VALID_SENDER_COLORS_ARRAY [[NSArray alloc] initWithObjects:@"red", @"blue" , @"gray", @"magenta", @"violet", @"olive", @"yellowgreen", @"darkred", @"darkgreen", @"darksalmon", @"darkcyan", @"darkyellow", @"mediumpurple", @"peru", @"olivedrab", @"royalred", @"darkorange", @"slateblue", @"slategray", @"goldenrod", @"orangered", @"tomato", @"dogderblue", @"steelblue", @"deeppink", @"saddlebrown", @"coral", @"royalblue", nil]

static NSArray *validSenderColors;

@interface NSMutableString (AIKeywordReplacementAdditions)
- (void) replaceKeyword:(NSString *)word withString:(NSString *)newWord;
@end

@implementation NSMutableString (AIKeywordReplacementAdditions)
- (void) replaceKeyword:(NSString *)keyWord withString:(NSString *)newWord
{
	if(!keyWord) return;
	if(!newWord) newWord = @"";
	[self replaceOccurrencesOfString:keyWord
						  withString:newWord
							 options:NSLiteralSearch
							   range:NSMakeRange(0, [self length])];
}
@end

@interface AIWebkitMessageViewStyle (PRIVATE)
- (id)initWithBundle:(NSBundle *)inBundle;
- (void)_loadTemplates;
- (NSMutableString *)_escapeStringForPassingToScript:(NSMutableString *)inString;
- (NSString *)noVariantName;
- (NSString *)iconPathForFileTransfer:(ESFileTransfer *)inObject;
- (NSString *)statusIconPathForListObject:(AIListObject *)inObject;
@end

@implementation AIWebkitMessageViewStyle

+ (id)messageViewStyleFromBundle:(NSBundle *)inBundle
{
	return [[[self alloc] initWithBundle:inBundle] autorelease];
}

/*!
 *	@brief Initialize
 */
- (id)initWithBundle:(NSBundle *)inBundle
{
	if ((self = [super init])) {
		styleBundle = [inBundle retain];
		stylePath = [[styleBundle resourcePath] retain];

		//Default behavior
		allowTextBackgrounds = YES;

		/* Our styles are versioned so we can change how they work without breaking compatibility.
		 *
		 * Version 0: Initial Webkit Version
		 * Version 1: Template.html now handles all scroll-to-bottom functionality.  It is no longer required to call the
		 *            scrollToBottom functions when inserting content.
		 * Version 2: No signifiant changes
		 * Version 3: main.css is no longer a separate style, it now serves as the base stylesheet and is imported by default.
		 *            The default variant is now a separate file in /variants like all other variants.
		 *			  Template.html now includes appendMessageNoScroll() and appendNextMessageNoScroll() which behave
		 *				the same as appendMessage() and appendNextMessage() in Versions 1 and 2 but without scrolling.
		 *
		 */
		styleVersion = [[styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_VERSION] intValue];

		//Pre-fetch our templates
		[self _loadTemplates];

		//Style flags
		allowsCustomBackground = ![[styleBundle objectForInfoDictionaryKey:@"DisableCustomBackground"] boolValue];
		transparentDefaultBackground = [[styleBundle objectForInfoDictionaryKey:@"DefaultBackgroundIsTransparent"] boolValue];

		combineConsecutive = ![[styleBundle objectForInfoDictionaryKey:@"DisableCombineConsecutive"] boolValue];

		NSNumber *tmpNum = [styleBundle objectForInfoDictionaryKey:@"ShowsUserIcons"];
		allowsUserIcons = (tmpNum ? [tmpNum boolValue] : YES);
		
		//User icon masking
		NSString *tmpName = [styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_USER_ICON_MASK];
		if (tmpName) userIconMask = [[NSImage alloc] initWithContentsOfFile:[stylePath stringByAppendingPathComponent:tmpName]];
	}

	return self;
}

/*!
 *	@brief Deallocate
 */
- (void)dealloc
{	
	[styleBundle release];
	[stylePath release];

	//Templates
	[headerHTML release];
	[footerHTML release];
	[baseHTML release];
	[contentInHTML release];
	[nextContentInHTML release];
	[contextInHTML release];
	[nextContextInHTML release];
	[contentOutHTML release];
	[nextContentOutHTML release];
	[contextOutHTML release];
	[nextContextOutHTML release];
	[statusHTML release];	

	[timeStampFormatter release];

	[customBackgroundPath release];
	[customBackgroundColor release];
	
	[userIconMask release];
	
	[super dealloc];
}

- (BOOL)isLegacy
{
	return styleVersion < LEGACY_VERSION_THRESHOLD;
}

#pragma mark Settings
- (BOOL)allowsCustomBackground
{
	return allowsCustomBackground;
}

- (BOOL)isBackgroundTransparent
{
	//Our custom background is only transparent if the user has set a custom color with an alpha component less than 1.0
	return ((!customBackgroundColor && transparentDefaultBackground) ||
		   (customBackgroundColor && [customBackgroundColor alphaComponent] < 0.99));
}

- (BOOL)allowsUserIcons
{
	return allowsUserIcons;
}

- (NSString *)defaultFontFamily
{
	return [styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_FAMILY];
}

- (NSNumber *)defaultFontSize
{
	return [styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_SIZE];
}

- (BOOL)hasHeader
{
	return headerHTML && [headerHTML length];
}

- (NSImage *)userIconMask
{
	return userIconMask;
}

#pragma mark Behavior

- (void)setDateFormat:(NSString *)format
{
	if (!format || [format length] == 0) {
		format = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO];
	}
	[timeStampFormatter release];
	timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO];
}

- (void)setShowUserIcons:(BOOL)inValue
{
	showUserIcons = inValue;
}

- (void)setShowHeader:(BOOL)inValue
{
	showHeader = inValue;
}

- (void)setUseCustomNameFormat:(BOOL)inValue
{
	useCustomNameFormat = inValue;
}

- (void)setNameFormat:(int)inValue
{
	nameFormat = inValue;
}

- (void)setAllowTextBackgrounds:(BOOL)inValue
{
	allowTextBackgrounds = inValue;
}

- (void)setCustomBackgroundPath:(NSString *)inPath
{
	if (customBackgroundPath != inPath) {
		[customBackgroundPath release];
		customBackgroundPath = [inPath retain];
	}
}

- (void)setCustomBackgroundType:(AIWebkitBackgroundType)inType
{
	customBackgroundType = inType;
}

- (void)setCustomBackgroundColor:(NSColor *)inColor
{
	if (customBackgroundColor != inColor) {
		[customBackgroundColor release];
		customBackgroundColor = [inColor retain];
	}
}

- (void)setShowIncomingMessageColors:(BOOL)inValue
{
	showIncomingColors = inValue;
}

- (void)setShowIncomingMessageFonts:(BOOL)inValue
{
	showIncomingFonts = inValue;
}


//Templates ------------------------------------------------------------------------------------------------------------
#pragma mark Templates
- (NSString *)baseTemplateWithVariant:(NSString *)variant chat:(AIChat *)chat
{
	NSMutableString	*templateHTML;

	//Old styles may be using an old custom 4 parameter baseHTML.  Styles version 3 and higher should
	//be using the bundled (or a custom) 5 parameter baseHTML.
	if (styleVersion < 3 && usingCustomBaseHTML) {
		templateHTML = [NSMutableString stringWithFormat:baseHTML,						//Template
			[[NSURL fileURLWithPath:stylePath] absoluteString],							//Base path
			[self pathForVariant:variant],												//Variant path
			((showHeader && headerHTML) ? headerHTML : @""),
			(footerHTML ? footerHTML : @"")];
	} else {
		templateHTML = [NSMutableString stringWithFormat:baseHTML,						//Template
			[[NSURL fileURLWithPath:stylePath] absoluteString],							//Base path
			(styleVersion < 3 ? @"" : @"@import url( \"main.css\" );"),					//Import main.css by default (For version 3 and newer styles)
			[self pathForVariant:variant],												//Variant path
			((showHeader && headerHTML) ? headerHTML : @""),
			(footerHTML ? footerHTML : @"")];
	}

	return [self fillKeywordsForBaseTemplate:templateHTML chat:chat];
}

- (NSString *)templateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar
{
	NSString	*template;
	
	//Get the correct template for what we're inserting
	if ([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
		if ([content isOutgoing]) {
			template = (contentIsSimilar ? nextContentOutHTML : contentOutHTML);
		} else {
			template = (contentIsSimilar ? nextContentInHTML : contentInHTML);
		}
	
	} else if ([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]) {
		if ([content isOutgoing]) {
			template = (contentIsSimilar ? nextContextOutHTML : contextOutHTML);
		} else {
			template = (contentIsSimilar ? nextContextInHTML : contextInHTML);
		}

	} else if([[content type] isEqualToString:CONTENT_FILE_TRANSFER_TYPE]) {
		template = [[fileTransferHTML mutableCopy] autorelease];
	}
	else {
		template = statusHTML;
	}
	
	return template;
}

/*!
 *	@brief Pre-fetch all the style templates
 *
 *	This needs to be called before either baseTemplate or templateForContent is called
 */
- (void)_loadTemplates
{		
	//Load the style's templates
	//We can't use NSString's initWithContentsOfFile here.  HTML files are interpreted in the defaultCEncoding
	//(which varies by system) when read that way.  We want to always interpret the files as UTF8.
	headerHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Header.html"]] retain];
	footerHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Footer.html"]] retain];
	baseHTML = [NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Template.html"]];

	//Starting with version 1, styles can choose to not include template.html.  If the template is not included 
	//Adium's default will be used.  This is preferred since any future template updates will apply to the style
	if ((!baseHTML || [baseHTML length] == 0) && styleVersion >= 1) {		
		baseHTML = [NSString stringWithContentsOfUTF8File:[[NSBundle bundleForClass:[self class]] pathForResource:@"Template" ofType:@"html"]];
		usingCustomBaseHTML = NO;
	} else {
		usingCustomBaseHTML = YES;
	}
	[baseHTML retain];	

	//Content Templates
	contentInHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Incoming/Content.html"]] retain];
	nextContentInHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Incoming/NextContent.html"]] retain];
	contentOutHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Outgoing/Content.html"]] retain];
	nextContentOutHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Outgoing/NextContent.html"]] retain];
		  
	//Context (Fall back on content if not present)
	contextInHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Incoming/Context.html"]] retain];
	nextContextInHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Incoming/NextContext.html"]] retain];
	if (!contextInHTML) contextInHTML = [contentInHTML retain];
	if (!nextContextInHTML) nextContextInHTML = [nextContentInHTML retain];

	contextOutHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Outgoing/Context.html"]] retain];
	nextContextOutHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Outgoing/NextContext.html"]] retain];
	if (!contextOutHTML) contextOutHTML = [contentOutHTML retain];
	if (!nextContextOutHTML) nextContextOutHTML = [nextContentOutHTML retain];

	//Status
	statusHTML = [[NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Status.html"]] retain];
	
	fileTransferHTML = [NSString stringWithContentsOfUTF8File:[stylePath stringByAppendingPathComponent:@"Incoming/FileTransferRequest.html"]];
	if(!fileTransferHTML) {
		fileTransferHTML = [contentInHTML mutableCopy];
		[(NSMutableString *)fileTransferHTML replaceKeyword:@"%message%"
												 withString:@"<p><img src=\"%fileIconPath%\" style=\"width:32px; height:32px; vertical-align:middle;\"></img><input type=\"button\" onclick=\"%saveFileAsHandler%\" value=\"Download %fileName%\"></p>"];
	}
	else
		[fileTransferHTML retain];
	
}

#pragma mark Scripts
- (NSString *)scriptForAppendingContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects
{
	NSMutableString	*newHTML;
	NSString		*script;
	
	//If combining of consecutive messages has been disabled, we treat all content as non-similar
	if (!combineConsecutive) contentIsSimilar = NO;
	
	//Fetch the correct template and substitute keywords for the passed content
	newHTML = [[[self templateForContent:content similar:contentIsSimilar] mutableCopy] autorelease];
	newHTML = [self fillKeywords:newHTML forContent:content];
	
	//BOM scripts vary by style version
	if (styleVersion >= 3) {
		if (willAddMoreContentObjects) {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE_NO_SCROLL : APPEND_MESSAGE_NO_SCROLL);
		} else {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE : APPEND_MESSAGE);
		}
	} else if (styleVersion >= 1) {
		script = (contentIsSimilar ? APPEND_NEXT_MESSAGE : APPEND_MESSAGE);
		
	} else {
		script = (contentIsSimilar ? APPEND_NEXT_MESSAGE_WITH_SCROLL : APPEND_MESSAGE_WITH_SCROLL);
	}
	
	return [NSString stringWithFormat:script, [self _escapeStringForPassingToScript:newHTML]]; 
}

- (NSString *)scriptForChangingVariant:(NSString *)variant
{
	return [NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");",[self pathForVariant:variant]];
}

- (NSString *)scriptForScrollingAfterAddingMultipleContentObjects
{
	if (styleVersion >= 3) {
		return @"alignChat(true);";
	}

	return nil;
}

/*!
 *	@brief Escape a string for passing to our BOM scripts
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

	return inString;
}

#pragma mark Variants

- (NSArray *)availableVariants
{
	NSMutableArray	*availableVariants = [NSMutableArray array];
	NSEnumerator	*enumerator = [[styleBundle pathsForResourcesOfType:@"css" inDirectory:@"Variants"] objectEnumerator];
	NSString		*path;
	
	//Build an array of all variant names
	while ((path = [enumerator nextObject])) {
		[availableVariants addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
	}

	//Style versions before 3 stored the default variant in a separate location.  They also allowed for this
	//varient name to not be specified, and would substitute a localized string in its place.
	if (styleVersion < 3) {
		[availableVariants addObject:[self noVariantName]];
	}
	
	//Alphabetize the variants
	[availableVariants sortUsingSelector:@selector(compare:)];
	
	return availableVariants;
}

- (NSString *)pathForVariant:(NSString *)variant
{
	//Styles before version 3 stored the default variant in main.css, and not in the variants folder.
	if (styleVersion < 3 && [variant isEqualToString:[self noVariantName]]) {
		return @"main.css";
	} else {
		return [NSString stringWithFormat:@"Variants/%@.css",variant];
	}
}

/*!
 *	@brief Base variant name for styles before version 2
 */
- (NSString *)noVariantName
{
	NSString	*noVariantName = [styleBundle objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
	return noVariantName ? noVariantName : AILocalizedString(@"Normal","Normal style variant menu item");
}

+ (NSString *)noVariantNameForBundle:(NSBundle *)inBundle
{
	NSString	*noVariantName = [inBundle objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
	return noVariantName ? noVariantName : AILocalizedString(@"Normal","Normal style variant menu item");	
}

- (NSString *)defaultVariant
{
	return styleVersion < 3 ? [self noVariantName] : [styleBundle objectForInfoDictionaryKey:@"DefaultVariant"];
}

+ (NSString *)defaultVariantForBundle:(NSBundle *)inBundle
{
	return [[inBundle objectForInfoDictionaryKey:KEY_WEBKIT_VERSION] intValue] < 3 ? 
		   [self noVariantNameForBundle:inBundle] : 
		   [inBundle objectForInfoDictionaryKey:@"DefaultVariant"];
}

#pragma mark Keyword replacement

- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content
{
	NSDate			*date = nil;
	NSRange			range;
	AIListObject	*contentSource = [content source];
	AIListObject	*theSource = ([contentSource isKindOfClass:[AIListContact class]] ?
								  [(AIListContact *)contentSource parentContact] :
								  contentSource);

	/*
		htmlEncodedMessage is only encoded correctly for AIContentMessages
		but we do it up here so that we can check for RTL/LTR text below without
		having to encode the message twice. This is less than ideal 
	 */
	NSString		*htmlEncodedMessage = [AIHTMLDecoder encodeHTML:[content message]
															headers:NO 
														   fontTags:([content isOutgoing] ?
																	 YES :
																	 showIncomingFonts)
												 includingColorTags:([content isOutgoing] ? 
																	 YES : 
																	 showIncomingColors)
													  closeFontTags:YES
														  styleTags:YES
										 closeStyleTagsOnFontChange:YES
													 encodeNonASCII:YES
													   encodeSpaces:YES
														 imagesPath:NSTemporaryDirectory()
												  attachmentsAsText:NO
										  onlyIncludeOutgoingImages:NO
													 simpleTagsOnly:NO
													 bodyBackground:NO];
		
		
	//date
	if ([content respondsToSelector:@selector(date)])
		date = [(AIContentMessage *)content date];
	
	//Replacements applicable to any AIContentObject
	[inString replaceKeyword:@"%time%" 
			  withString:(date != nil ? [timeStampFormatter stringForObjectValue:date] : @"")];
	
	[inString replaceKeyword:@"%senderStatusIcon%"
				  withString:[self statusIconPathForListObject:theSource]];
	
	if(!validSenderColors) validSenderColors = VALID_SENDER_COLORS_ARRAY;
	[inString replaceKeyword:@"%senderColor%"
				  withString:[validSenderColors objectAtIndex:([[contentSource UID] hash] % ([validSenderColors count] - 1))]];
	
	//HAX. The odd conditional here detects the rtl html that our html parser spits out.
	[inString replaceKeyword:@"%messageDirection%"
				  withString:(([inString rangeOfString:@"<DIV dir=\"rtl\">"].location != NSNotFound) ? @"rtl" : @"ltr")];
	
	//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
	do{
		range = [inString rangeOfString:@"%time{"];
		if (range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%"];
			if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
				if (date) {
					NSString *timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];
					NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																			allowNaturalLanguage:NO];
					[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
											withString:[dateFormatter stringForObjectValue:date]];
					[dateFormatter release];
					
				} else {
					[inString deleteCharactersInRange:NSUnionRange(range, endRange)];
				}
				
			}
		}
	} while (range.location != NSNotFound);
	
	//message stuff
	if ([content isKindOfClass:[AIContentMessage class]]) {
		do{
			range = [inString rangeOfString:@"%userIconPath%"];
			if (range.location != NSNotFound) {
				NSString    *userIconPath;
				NSString	*replacementString;
				
				userIconPath = [theSource statusObjectForKey:KEY_WEBKIT_USER_ICON];
				if (!userIconPath) {
					userIconPath = [theSource statusObjectForKey:@"UserIconPath"];
				}
					
				if (showUserIcons && userIconPath) {
					replacementString = [NSString stringWithFormat:@"file://%@", userIconPath];
					
				} else {
					replacementString = ([content isOutgoing]
										 ? @"Outgoing/buddy_icon.png" 
										 : @"Incoming/buddy_icon.png");
				}
				
				[inString replaceCharactersInRange:range withString:replacementString];
			}
		} while (range.location != NSNotFound);
		
		//Use [content source] directly rather than the potentially-metaContact theSource
		NSString *formattedUID = [contentSource formattedUID];
		[inString replaceKeyword:@"%senderScreenName%" 
					  withString:[(formattedUID ?
								   formattedUID :
								   [contentSource displayName]) stringByEscapingForXMLWithEntities:nil]];
        
		do{
			range = [inString rangeOfString:@"%sender%"];
			if (range.location != NSNotFound) {
				NSString		*senderDisplay = nil;
				if (useCustomNameFormat) {
					NSString		*displayName = [theSource displayName];
					NSString		*formattedUID = [theSource formattedUID];
					
					if (formattedUID && ![displayName isEqualToString:formattedUID]) {
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
							case Display_Name: {
								senderDisplay = displayName;
							}
						}
					}
					if (!senderDisplay) {
						senderDisplay = displayName;
					}
				} else {
					senderDisplay = [theSource longDisplayName];
				}
				
				if ([(AIContentMessage *)content isAutoreply]) {
					senderDisplay = [NSString stringWithFormat:@"%@ %@",senderDisplay,AILocalizedString(@"(Autoreply)","Short word inserted after the sender's name when displaying a message which was an autoresponse")];
				}
					
				[inString replaceCharactersInRange:range withString:[senderDisplay stringByEscapingForXMLWithEntities:nil]];
			}
		} while (range.location != NSNotFound);
        
		do {
			range = [inString rangeOfString:@"%senderDisplayName%"];
			if (range.location != NSNotFound) {
				NSString *serversideDisplayName = ([theSource isKindOfClass:[AIListContact class]] ?
												   [(AIListContact *)theSource serversideDisplayName] :
												   nil);
				if (!serversideDisplayName) {
					serversideDisplayName = [theSource displayName];
				}
				
				[inString replaceCharactersInRange:range
										withString:[serversideDisplayName stringByEscapingForXMLWithEntities:nil]];
			}
		} while (range.location != NSNotFound);
		
		[inString replaceKeyword:@"%service%" 
					  withString:[[contentSource service] shortDescription]];

		//Blatantly stealing the date code for the background color script.
		do{
			range = [inString rangeOfString:@"%textbackgroundcolor{"];
			if (range.location != NSNotFound) {
				NSRange endRange;
				endRange = [inString rangeOfString:@"}%"];
				if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
					NSString *transparency = [inString substringWithRange:NSMakeRange(NSMaxRange(range),
																					  (endRange.location - NSMaxRange(range)))];
					
					if (allowTextBackgrounds && showIncomingColors) {
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
																imagesPath:NSTemporaryDirectory()
														 attachmentsAsText:NO
												 onlyIncludeOutgoingImages:NO
															simpleTagsOnly:NO
															bodyBackground:YES];
						hexcode = [NSScanner scannerWithString:thisIsATemporaryString];
						[hexcode  scanHexInt:&rgb];
						if (![thisIsATemporaryString length] && rgb == 0) {
							[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:@""];
						} else {
							red = (rgb & 0xff0000) >> 16;
							green = (rgb & 0x00ff00) >> 8;
							blue = rgb & 0x0000ff;
							[inString replaceCharactersInRange:NSUnionRange(range, endRange)
													withString:[NSString stringWithFormat:@"rgba(%d, %d, %d, %@)", red, green, blue, transparency]];
						}
					} else {
						[inString replaceCharactersInRange:NSUnionRange(range, endRange) withString:@""];
					}
				} else if (endRange.location == NSMaxRange(range)) {
					if (allowTextBackgrounds && showIncomingColors) {
						NSString *thisIsATemporaryString;
						
						thisIsATemporaryString = [AIHTMLDecoder encodeHTML:[content message] headers:NO 
																  fontTags:NO
														includingColorTags:NO
															 closeFontTags:NO
																 styleTags:NO
												closeStyleTagsOnFontChange:NO
															encodeNonASCII:NO
															  encodeSpaces:NO
																imagesPath:NSTemporaryDirectory()
														 attachmentsAsText:NO
												 onlyIncludeOutgoingImages:NO
															simpleTagsOnly:NO
															bodyBackground:YES];
						[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
												withString:[NSString stringWithFormat:@"#%@", thisIsATemporaryString]];
					} else {
						[inString replaceCharactersInRange:NSUnionRange(range, endRange)
												withString:@""];
					}	
				}
			}
		} while (range.location != NSNotFound);
		
		if ([content isKindOfClass:[ESFileTransfer class]]) { //file transfers are an AIContentMessage subclass
		
			ESFileTransfer *transfer = (ESFileTransfer *)content;
			NSString *fileName = [[transfer remoteFilename] stringByEscapingForXMLWithEntities:nil];
			do{
				range = [inString rangeOfString:@"%fileIconPath%"];
				NSString *iconPath = [self iconPathForFileTransfer:transfer];
				NSImage *icon = [transfer iconImage];
				[[icon TIFFRepresentation] writeToFile:iconPath atomically:YES];
				if (range.location != NSNotFound) {
					[inString replaceCharactersInRange:range withString:iconPath];
				}
			} while (range.location != NSNotFound);
			
			[inString replaceKeyword:@"%fileName%"
						  withString:fileName];
			
			[inString replaceKeyword:@"%saveFileHandler%"
						  withString:[NSString stringWithFormat:@"client.handleFileTransfer('Save', '%@')", fileName]];
			
			[inString replaceKeyword:@"%saveFileAsHandler%"
						  withString:[NSString stringWithFormat:@"client.handleFileTransfer('SaveAs', '%@')", fileName]];
			
			[inString replaceKeyword:@"%cancelRequestHandler%"
						  withString:[NSString stringWithFormat:@"client.handleFileTransfer('Cancel', '%@')", fileName]];
			
		}
		
		
		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if (range.location != NSNotFound) {
			[inString replaceCharactersInRange:range withString:htmlEncodedMessage];
		}
		
	} else if ([content isKindOfClass:[AIContentStatus class]]) {
		NSString	*statusPhrase;
		BOOL		replacedStatusPhrase = NO;
		
		[inString replaceKeyword:@"%status%" 
				  withString:[[(AIContentStatus *)content status] stringByEscapingForXMLWithEntities:nil]];
		
		[inString replaceKeyword:@"%statusSender%" 
				  withString:[[theSource displayName] stringByEscapingForXMLWithEntities:nil]];

		if ((statusPhrase = [[content userInfo] objectForKey:@"Status Phrase"])) {
			do{
				range = [inString rangeOfString:@"%statusPhrase%"];
				if (range.location != NSNotFound) {
					[inString replaceCharactersInRange:range 
											withString:[statusPhrase stringByEscapingForXMLWithEntities:nil]];
					replacedStatusPhrase = YES;
				}
			} while (range.location != NSNotFound);
		}
		
		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if (range.location != NSNotFound) {
			NSString	*messageString;

			if (replacedStatusPhrase) {
				//If the status phrase was used, clear the message tag
				messageString = @"";
			} else {
				messageString = [AIHTMLDecoder encodeHTML:[content message]
												  headers:NO 
												 fontTags:NO
									   includingColorTags:NO
											closeFontTags:YES
												styleTags:NO
							   closeStyleTagsOnFontChange:YES
										   encodeNonASCII:YES
											 encodeSpaces:YES
											   imagesPath:NSTemporaryDirectory()
										attachmentsAsText:NO
								onlyIncludeOutgoingImages:NO
										   simpleTagsOnly:NO
										   bodyBackground:NO];
			}
			
			[inString replaceCharactersInRange:range withString:messageString];
		}
	}

	return inString;
}

- (NSMutableString *)fillKeywordsForBaseTemplate:(NSMutableString *)inString chat:(AIChat *)chat
{
	NSRange	range;
	
	[inString replaceKeyword:@"%chatName%"
				  withString:[[chat displayName] stringByEscapingForXMLWithEntities:nil]];

	NSString * sourceName = [[[chat account] displayName] stringByEscapingForXMLWithEntities:nil];
	if(!sourceName) sourceName = @" ";
	[inString replaceKeyword:@"%sourceName%"
				  withString:sourceName];
	
	NSString *destinationName = [[chat listObject] displayName];
	if (!destinationName) destinationName = [chat displayName];
	[inString replaceKeyword:@"%destinationName%"
				  withString:destinationName];
	
	NSString *serversideDisplayName = [[chat listObject] serversideDisplayName];
	if (!serversideDisplayName) serversideDisplayName = [chat displayName];
	[inString replaceKeyword:@"%destinationDisplayName%"
				  withString:[serversideDisplayName stringByEscapingForXMLWithEntities:nil]];
		
	AIListContact	*listObject = [chat listObject];
	NSString		*iconPath = nil;
	
	if (listObject) {
		iconPath = [listObject statusObjectForKey:KEY_WEBKIT_USER_ICON];
		if (!iconPath) {
			iconPath = [listObject statusObjectForKey:@"UserIconPath"];
		}
	}
	[inString replaceKeyword:@"%incomingIconPath%"
				  withString:(iconPath ? iconPath : @"incoming_icon.png")];
	
	AIListObject	*account = [chat account];
	iconPath = nil;
	
	if (account) {
		iconPath = [account statusObjectForKey:KEY_WEBKIT_USER_ICON];
		if (!iconPath) {
			iconPath = [account statusObjectForKey:@"UserIconPath"];
		}
	}
	[inString replaceKeyword:@"%outgoingIconPath%"
				  withString:(iconPath ? iconPath : @"outgoing_icon.png")];
	
	[inString replaceKeyword:@"%timeOpened%"
				  withString:[timeStampFormatter stringForObjectValue:[chat dateOpened]]];
	
	//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
	do{
		range = [inString rangeOfString:@"%timeOpened{"];
		if (range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%"];

			if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {				
				NSString		*timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];
				NSDateFormatter	*dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeFormat 
																		allowNaturalLanguage:NO];

				[inString replaceCharactersInRange:NSUnionRange(range, endRange) 
										withString:[dateFormatter stringForObjectValue:[chat dateOpened]]];
				[dateFormatter release];
				
			}
		}
	} while (range.location != NSNotFound);
	
	//Background
	{
		range = [inString rangeOfString:@"==bodyBackground=="];
		
		if (range.location != NSNotFound) { //a backgroundImage tag is not required
			NSMutableString *bodyTag = nil;

			if (allowsCustomBackground && (customBackgroundPath || customBackgroundColor)) {				
				bodyTag = [[[NSMutableString alloc] init] autorelease];
				
				if (customBackgroundPath) {
					if ([customBackgroundPath length]) {
						switch (customBackgroundType) {
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
					} else {
						[bodyTag appendString:@"background-image: none; "];
					}
				}
				if (customBackgroundColor) {
					float red, green, blue, alpha;
					[customBackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
					[bodyTag appendString:[NSString stringWithFormat:@"background-color: rgba(%i, %i, %i, %f); ", (int)(red * 255.0), (int)(green * 255.0), (int)(blue * 255.0), alpha]];
				}
 			}
			
			//Replace the body background tag
 			[inString replaceCharactersInRange:range withString:(bodyTag ? (NSString *)bodyTag : @"")];
 		}
 	}

	return inString;
}

#pragma mark Icons

- (NSString *)iconPathForFileTransfer:(ESFileTransfer *)inObject
{
	NSString	*filename = [NSString stringWithFormat:@"TEMP-%@%@.tiff", [inObject remoteFilename], [NSString randomStringOfLength:5]];
	return [[[AIObject sharedAdiumInstance] cachesPath] stringByAppendingPathComponent:filename];
}

- (NSString *)statusIconPathForListObject:(AIListObject *)inObject
{
	if(!statusIconPathCache) statusIconPathCache = [[NSMutableDictionary alloc] init];
	NSImage *icon = [AIStatusIcons statusIconForListObject:inObject
													  type:AIStatusIconTab
												 direction:AIIconNormal];
	NSString *statusName = [AIStatusIcons statusNameForListObject:inObject];
	if(!statusName)
		statusName = @"UnknownStatus";
	NSString *path = [statusIconPathCache objectForKey:statusName];
	if(!path)
	{
		path = [[[AIObject sharedAdiumInstance] cachesPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"TEMP-%@%@.tiff", statusName, [NSString randomStringOfLength:5]]];
		[[icon TIFFRepresentation] writeToFile:path atomically:YES];
		[statusIconPathCache setObject:path forKey:statusName];
	}

	return path;
}

@end
