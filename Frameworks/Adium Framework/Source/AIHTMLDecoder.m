/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2006, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/*
	A quick and simple HTML to Attributed string converter (ha! --jmelloy)
*/

#import <Adium/AIHTMLDecoder.h>

#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISetAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>

#import <Adium/AITextAttachmentExtension.h>
#import <Adium/ESFileWrapperExtension.h>
#import <Adium/AIXMLElement.h>

#import <FriBidi/NSString-FBAdditions.h>

#include <CoreServices/CoreServices.h>

int HTMLEquivalentForFontSize(int fontSize);

@interface AIHTMLDecoder (PRIVATE)
- (void)processFontTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (void)processBodyTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (void)processLinkTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (void)processSpanTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (void)processDivTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (NSAttributedString *)processImgTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (BOOL)appendImage:(NSImage *)attachmentImage
			 atPath:(NSString *)inPath
		   toString:(NSMutableString *)string
		   withName:(NSString *)inName 
		 imageClass:(NSString *)imageClass
		 imagesPath:(NSString *)imagesPath;
@end

@interface NSString (AIHTMLDecoderAdditions)
- (NSString *)stringByConvertingWingdingsToUnicode;
- (NSString *)stringByConvertingSymbolToSymbolUnicode;
@end

@implementation AIHTMLDecoder

static AITextAttributes *_defaultTextDecodingAttributes = nil;
static NSString			*horizontalRule = nil;

+ (void)initialize
{
	if (!_defaultTextDecodingAttributes) {
		_defaultTextDecodingAttributes = [[AITextAttributes textAttributesWithFontFamily:@"Lucida Grande" traits:0 size:12] retain];
	}

	//Set up the horizontal rule which will be searched-for when encoding and inserted when decoding
	if (!horizontalRule) {
#define HORIZONTAL_BAR			0x2013
#define HORIZONTAL_RULE_LENGTH	12

		const unichar separatorUTF16[HORIZONTAL_RULE_LENGTH] = {
			'\n', HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR,
			HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, '\n'
		};
		horizontalRule = [[NSString alloc] initWithCharacters:separatorUTF16 length:HORIZONTAL_RULE_LENGTH];
	}	
}

+ (AIHTMLDecoder *)decoder
{
	return [[[self alloc] init] autorelease];
}

- (id)initWithHeaders:(BOOL)includeHeaders
			 fontTags:(BOOL)includeFontTags
		closeFontTags:(BOOL)closeFontTags
			colorTags:(BOOL)includeColorTags
			styleTags:(BOOL)includeStyleTags
	   encodeNonASCII:(BOOL)encodeNonASCII
		 encodeSpaces:(BOOL)encodeSpaces
	attachmentsAsText:(BOOL)attachmentsAsText
onlyIncludeOutgoingImages:(BOOL)onlyIncludeOutgoingImages
	   simpleTagsOnly:(BOOL)simpleOnly
	   bodyBackground:(BOOL)bodyBackground
{
	if ((self = [self init])) {
		thingsToInclude.headers							= includeHeaders;
		thingsToInclude.fontTags						= includeFontTags;
		thingsToInclude.closingFontTags					= closeFontTags;
		thingsToInclude.colorTags						= includeColorTags;
		thingsToInclude.styleTags						= includeStyleTags;
		thingsToInclude.nonASCII						= encodeNonASCII;
		thingsToInclude.allSpaces						= encodeSpaces;
		thingsToInclude.attachmentTextEquivalents		= attachmentsAsText;
		thingsToInclude.onlyIncludeOutgoingImages	= onlyIncludeOutgoingImages;
		thingsToInclude.simpleTagsOnly					= simpleOnly;
		thingsToInclude.bodyBackground					= bodyBackground;
		
		thingsToInclude.allowAIMsubprofileLinks			= NO;
	}
	
	return self;
}

+ (AIHTMLDecoder *)decoderWithHeaders:(BOOL)includeHeaders
							 fontTags:(BOOL)includeFontTags
						closeFontTags:(BOOL)closeFontTags
							colorTags:(BOOL)includeColorTags
							styleTags:(BOOL)includeStyleTags
					   encodeNonASCII:(BOOL)encodeNonASCII
						 encodeSpaces:(BOOL)encodeSpaces
					attachmentsAsText:(BOOL)attachmentsAsText
	   onlyIncludeOutgoingImages:(BOOL)onlyIncludeOutgoingImages
					   simpleTagsOnly:(BOOL)simpleOnly
					   bodyBackground:(BOOL)bodyBackground
{
	return [[[self alloc] initWithHeaders:includeHeaders
								 fontTags:includeFontTags
							closeFontTags:closeFontTags
								colorTags:includeColorTags
								styleTags:includeStyleTags
						   encodeNonASCII:encodeNonASCII
							 encodeSpaces:encodeSpaces
						attachmentsAsText:attachmentsAsText
		   onlyIncludeOutgoingImages:onlyIncludeOutgoingImages
						   simpleTagsOnly:simpleOnly
						   bodyBackground:bodyBackground] autorelease];
}

#pragma mark Work methods

/*!
 * @brief Parse arguments in a string
 *
 * The arguments are returned in an NSDictionary whose keys are all-lowercase
 */
- (NSDictionary *)parseArguments:(NSString *)arguments
{
	NSMutableDictionary		*argDict;
	NSScanner				*scanner;
	static NSCharacterSet	*equalsSet = nil,
		*dquoteSet = nil,
		*squoteSet = nil,
		*spaceSet = nil;
	NSString				*key = nil, *value = nil;

	//Setup
	if (!equalsSet) equalsSet = [[NSCharacterSet characterSetWithCharactersInString:@"="]  retain];
	if (!dquoteSet) dquoteSet = [[NSCharacterSet characterSetWithCharactersInString:@"\""] retain];
	if (!squoteSet) squoteSet = [[NSCharacterSet characterSetWithCharactersInString:@"'"]  retain];
	if (!spaceSet)  spaceSet  = [[NSCharacterSet characterSetWithCharactersInString:@" "]  retain];

	scanner = [NSScanner scannerWithString:arguments];
	argDict = [NSMutableDictionary dictionary];

	while (![scanner isAtEnd]) {
		BOOL	validKey, validValue;

		//Find a tag
		validKey = [scanner scanUpToCharactersFromSet:equalsSet intoString:&key];
		[scanner scanCharactersFromSet:equalsSet intoString:nil];

		//check for quotes
		if ([scanner scanCharactersFromSet:dquoteSet intoString:nil]) {
			validValue = [scanner scanUpToCharactersFromSet:dquoteSet intoString:&value];
			[scanner scanCharactersFromSet:dquoteSet intoString:nil];
		} else if ([scanner scanCharactersFromSet:squoteSet intoString:nil]) {
			validValue = [scanner scanUpToCharactersFromSet:squoteSet intoString:&value];
			[scanner scanCharactersFromSet:squoteSet intoString:nil];
		} else {
			validValue = [scanner scanUpToCharactersFromSet:spaceSet intoString:&value];
		}

		//Store in dict
		if (validValue && value != nil && [value length] != 0 && validKey && key != nil && [key length] != 0) { //Watch out for invalid & empty tags
			[argDict setObject:value forKey:[key lowercaseString]];
		}
	}

	return argDict;
}

- (NSString *)encodeLooseHTML:(NSAttributedString *)inMessage imagesPath:(NSString *)imagesSavePath
{
	NSFontManager	*fontManager = [NSFontManager sharedFontManager];
	NSRange			 searchRange;
	NSColor			*pageColor = nil;
	BOOL			 openFontTag = NO;

	//Setup the incoming message as a regular string, and get its length
	NSString		*inMessageString = [inMessage string];
	unsigned		 messageLength = [inMessageString length];
	
	//Setup the destination HTML string
	NSMutableString *string = [NSMutableString string];
	if (thingsToInclude.headers) {
		[string appendString:@"<HTML>"];
	}

	//If the text is right-to-left, enclose all our HTML in an rtl DIV tag
	BOOL	rightToLeft = NO;
	if (!thingsToInclude.simpleTagsOnly) {
		if (messageLength > 0) {
			//First, attempt to figure the base writing direction of our message based on its content
			NSWritingDirection	dir = [inMessageString baseWritingDirection];

			if ([NSApp isOnTigerOrBetter]) {
				//If that doesn't work, try using the writing direction of the input field
				if (dir == NSWritingDirectionNatural) {
					dir = [[inMessage attribute:NSParagraphStyleAttributeName
										atIndex:0
								 effectiveRange:nil] baseWritingDirection];
					
					//If the input field's writing direction is NSWritingDirectionNatural, we shall figure what it really means.
					//The natural writing direction is determined by the system based on the current active localization of the app.
					if (dir == NSWritingDirectionNatural)
						dir = [NSParagraphStyle defaultWritingDirectionForLanguage:nil];
				}
			} else {
				dir = [NSParagraphStyle defaultWritingDirectionForLanguage:nil];				
			}
			
			if (dir == NSWritingDirectionRightToLeft) {
				[string appendString:@"<DIV dir=\"rtl\">"];
				rightToLeft = YES;
			}
		}
	}	
	
	//Setup the default attributes
	NSString		*currentFamily = [@"Helvetica" retain];
	NSString		*currentColor = nil;
	NSString		*currentBackColor = nil;
	int				 currentSize = 12;
	BOOL			 currentItalic = NO;
	BOOL			 currentBold = NO;
	BOOL			 currentUnderline = NO;
	BOOL			 currentStrikethrough = NO;
	NSString		*link = nil;
	NSString		*oldLink = nil;
	
	//Append the body tag (If there is a background color)
	if (thingsToInclude.headers &&
	   (messageLength > 0) &&
	   (pageColor = [inMessage attribute:AIBodyColorAttributeName
								 atIndex:0
						  effectiveRange:nil])) {
		[string appendString:@"<BODY BGCOLOR=\"#"];
		[string appendString:[pageColor hexString]];
		[string appendString:@"\">"];
	}

	//Loop through the entire string
	searchRange = NSMakeRange(0,0);
	while (searchRange.location < messageLength) {
		NSDictionary	*attributes = [inMessage attributesAtIndex:searchRange.location effectiveRange:&searchRange];
		NSFont			*font = [attributes objectForKey:NSFontAttributeName];
		NSString		*color = (thingsToInclude.colorTags ? [[attributes objectForKey:NSForegroundColorAttributeName] hexString] : nil);
		NSString		*backColor = (thingsToInclude.colorTags ? [[attributes objectForKey:NSBackgroundColorAttributeName] hexString] : nil);
		NSString		*familyName = [font familyName];
		float			 pointSize = [font pointSize];

		NSFontTraitMask	 traits = [fontManager traitsOfFont:font];
		BOOL			 hasUnderline = [[attributes objectForKey:NSUnderlineStyleAttributeName] intValue];
		BOOL			 hasStrikethrough = [[attributes objectForKey:NSStrikethroughStyleAttributeName] intValue];
		BOOL			 isBold = (traits & NSBoldFontMask);
		BOOL			 isItalic = (traits & NSItalicFontMask);
		
		link = [[attributes objectForKey:NSLinkAttributeName] absoluteString];
		
		//If we had a link on the last pass, and we don't now or we have a different one, close the link tag
		if (oldLink &&
			(!link || (([link length] != 0) && ![oldLink isEqualToString:link]))) {

			//Close Link
			[string appendString:@"</a>"];
			oldLink = nil;
		}
		
		NSMutableString	*chunk = [[inMessageString substringWithRange:searchRange] mutableCopy];

		//Font (If the color, font, or size has changed)
		BOOL changedSize = (pointSize != currentSize);
		BOOL changedColor = ((color && ![color isEqualToString:currentColor]) || (!color && currentColor));
		BOOL changedBackColor = ((backColor && ![backColor isEqualToString:currentBackColor]) || (!backColor && currentBackColor));
		if((thingsToInclude.fontTags && (changedSize || ![familyName isEqualToString:currentFamily])) ||
		   changedColor || changedBackColor) {

			//Close any existing font tags, and open a new one
			if (thingsToInclude.closingFontTags && openFontTag) {
				[string appendString:@"</FONT>"];
			}
			if (!thingsToInclude.simpleTagsOnly) {
				openFontTag = YES;
				//Leave the <FONT open since we'll add the rest of the font tag on below
				[string appendString:@"<FONT"];
			}

			//Family
			if (thingsToInclude.fontTags && familyName && (![familyName isEqualToString:currentFamily] || thingsToInclude.closingFontTags)) {
				if (thingsToInclude.simpleTagsOnly) {
					[string appendString:[NSString stringWithFormat:@"<FONT FACE=\"%@\">",familyName]];
				} else {
					//(traits | NSNonStandardCharacterSetFontMask) seems to be the proper test... but it is true for all fonts!
					//NSMacOSRomanStringEncoding seems to be the encoding of all standard Roman fonts... and langNum="11" seems to make the others send properly.
					//It serves us well here.  Once non-AIM HTML is coming through, this will probably need to be an option in the function call.
					if ([font mostCompatibleStringEncoding] != NSMacOSRomanStringEncoding) {
						[string appendString:[NSString stringWithFormat:@" FACE=\"%@\" LANG=\"11\"",familyName]];
					} else {
						[string appendString:[NSString stringWithFormat:@" FACE=\"%@\"",familyName]];
					}

				}
				[currentFamily release]; currentFamily = [familyName retain];
			}

			//Size
			if (!thingsToInclude.simpleTagsOnly) {
				[string appendString:[NSString stringWithFormat:@" ABSZ=%i SIZE=%i", (int)pointSize, HTMLEquivalentForFontSize((int)pointSize)]];
				currentSize = pointSize;
			}

			//Color
			if (color) {
				if (thingsToInclude.simpleTagsOnly) {
					[string appendString:[NSString stringWithFormat:@"<FONT COLOR=\"#%@\">",color]];	
				} else {
					[string appendString:[NSString stringWithFormat:@" COLOR=\"#%@\"",color]];
				}
			}
			//Background Color per tag
			if (backColor) {
				if (!thingsToInclude.simpleTagsOnly) {	
					[string appendString:[NSString stringWithFormat:@" BACK=\"#%@\"",backColor]];
				}
			}
			
			if (color != currentColor) {
				[currentColor release]; currentColor = [color retain];
			}
			
			if (backColor != currentBackColor) {
				[currentBackColor release]; currentBackColor = [backColor retain];
			}

			//Close the font tag if necessary
			if (!thingsToInclude.simpleTagsOnly) {
				[string appendString:@">"];
			}
		}

		//Style (Bold, italic, underline, strikethrough)
		if (thingsToInclude.styleTags) {			
			if (currentItalic && !isItalic) {
				[string appendString:@"</I>"];
				currentItalic = NO;
			} else  if (!currentItalic && isItalic) {
				[string appendString:@"<I>"];
				currentItalic = YES;
			}

			if (currentUnderline && !hasUnderline) {
				[string appendString:@"</U>"];
				currentUnderline = NO;
			} else if (!currentUnderline && hasUnderline) {
				[string appendString:@"<U>"];
				currentUnderline = YES;
			}

			if (currentBold && !isBold) {
				[string appendString:@"</B>"];
				currentBold = NO;
			} else if (!currentBold && isBold) {
				[string appendString:@"<B>"];
				currentBold = YES;
			}
        
			if (currentStrikethrough && !hasStrikethrough) {
				[string appendString:@"</S>"];
				currentStrikethrough = NO;
			} else if (!currentStrikethrough && hasStrikethrough) {
				[string appendString:@"<S>"];
				currentStrikethrough = YES;
			}
		}

		//Link
		if (!oldLink && link && [link length] != 0) {
			NSString	*linkString = ([link isKindOfClass:[NSURL class]] ? [(NSURL *)link absoluteString] : link);

			[string appendString:@"<a href=\""];
			
			/* AIM can handle %n in links, which is highly invalid for a real URL.
			 * If thingsToInclude.allowAIMsubprofileLinks is YES, and a %25n is in the link, replace the escaped version
			 * which was used within Adium [so that NSURL didn't balk] with %n, which is what other AIM clients will
			 * be expecting.
			 */
			if (thingsToInclude.allowAIMsubprofileLinks && 
			   ([linkString rangeOfString:@"%25n"].location != NSNotFound)) {
				NSMutableString	*fixedLinkString = [[linkString mutableCopy] autorelease];
				[fixedLinkString replaceOccurrencesOfString:@"%25n"
												 withString:@"%n"
													options:NSLiteralSearch
													  range:NSMakeRange(0, [fixedLinkString length])];
				linkString = fixedLinkString;
			}
			
			[string appendString:linkString];
			if (!thingsToInclude.simpleTagsOnly) {
				[string appendString:@"\" title=\""];
				[string appendString:linkString];
			}
			[string appendString:@"\">"];
			
			oldLink = linkString;
		}

		//Image Attachments
		if ([attributes objectForKey:NSAttachmentAttributeName]) {

			//Each attachment takes a character.. they are grouped by the attribute scan
			for (int i = 0; (i < searchRange.length); i++) { 
				NSTextAttachment *textAttachment = [[inMessage attributesAtIndex:searchRange.location+i 
																  effectiveRange:nil] objectForKey:NSAttachmentAttributeName];

				if (textAttachment) {
					if (![textAttachment isKindOfClass:[AITextAttachmentExtension class]]) {
						NSLog(@"Message %@ gave an NSTextAttachment %@ - why is it not an AITextAttachmentExtension?",
							  inMessage,
							  textAttachment);
						continue;
					}
					AITextAttachmentExtension *attachment = (AITextAttachmentExtension *)textAttachment;
					/* If we have a path to which we want to save any images and either
					 *		the attachment should save such images OR
					 *		the attachment is a plain NSTextAttachment and so doesn't respond to shouldSaveImageForLogging
					 */						
					BOOL shouldSaveImage = (imagesSavePath &&
											((![attachment respondsToSelector:@selector(shouldSaveImageForLogging)] ||
											  [attachment shouldSaveImageForLogging])));
					
					/* We want attachments as images where appropriate. We either want all images (we don't want only outgoing images) or
					 * this attachment may be sent as an image rather than as text.
					 */						
					BOOL shouldIncludeImageWithoutSaving = (!thingsToInclude.attachmentTextEquivalents &&
															(!thingsToInclude.onlyIncludeOutgoingImages || (![attachment respondsToSelector:@selector(shouldAlwaysSendAsText)] ||
																											![attachment shouldAlwaysSendAsText])));
					BOOL appendedImage = NO;

					if (shouldSaveImage || shouldIncludeImageWithoutSaving) {
						NSString	*existingPath, *imageName;
						NSImage		*image;
						
						//We want to use the image; collect all the information we have available
						existingPath = ([attachment respondsToSelector:@selector(path)] ?
										[attachment performSelector:@selector(path)] :
										nil);
						imageName = [attachment string];
						
						image = nil;

						/*
							Although PDFs are treated as images on OSX, they can cause issues on other platforms.
							Also, moreso than most other images, they can be too large to display inline.
						 */
						if(!existingPath || ![[existingPath pathExtension] isEqualToString:@"pdf"])
						{
							if ([attachment respondsToSelector:@selector(image)])
								image = [attachment performSelector:@selector(image)];
							else if ([[attachment attachmentCell] respondsToSelector:@selector(image)])
								image = [[attachment attachmentCell] performSelector:@selector(image)];
						}

						if (existingPath || image) {
							appendedImage = [self appendImage:image
													   atPath:existingPath
													 toString:string
													 withName:imageName
												   imageClass:[attachment imageClass]
												   imagesPath:(shouldIncludeImageWithoutSaving ? imagesSavePath : nil)];
							
							//We were succesful appending the image tag, so release this chunk
							[chunk release]; chunk = nil;	
						}
					}
					
					if (!appendedImage) {
						//We should replace the attachment with its textual equivalent if we didn't append an image
						NSString	*attachmentString;
						if ((attachmentString = [attachment string])) {
							[string appendString:attachmentString];
						}
						
						[chunk release]; chunk = nil;
					}
				}
			}
		}

		if (chunk) {
			NSRange	fullRange;
			unsigned int replacements;

			//Escape special HTML characters.
			fullRange = NSMakeRange(0, [chunk length]);

			replacements = [chunk replaceOccurrencesOfString:@"&" withString:@"&amp;"
													 options:NSLiteralSearch range:fullRange];
			fullRange.length += (replacements * 4);
				
			replacements = [chunk replaceOccurrencesOfString:@"<" withString:@"&lt;"
									  options:NSLiteralSearch range:fullRange];
			fullRange.length += (replacements * 3);
			
			replacements = [chunk replaceOccurrencesOfString:@">" withString:@"&gt;"
													 options:NSLiteralSearch range:fullRange];
			fullRange.length += (replacements * 3);

			//Horizontal rule
			replacements = [chunk replaceOccurrencesOfString:horizontalRule withString:@"<HR>"
													 options:NSLiteralSearch range:fullRange];
			if (replacements) {
				fullRange.length = [chunk length];
			}

			if (thingsToInclude.allSpaces) {
				/* Replace the tabs first, if they exist, so that it creates a leading " " when the tab is the initial character, and 
				 * so subsequent tab formatting is preserved.
				 */
				replacements = [chunk replaceOccurrencesOfString:@"\t" 
													  withString:@" &nbsp;&nbsp;&nbsp;"
														 options:NSLiteralSearch
														   range:fullRange];
				fullRange.length += (replacements * 18);

				//If the first character is a space, replace that leading ' ' with "&nbsp;" to preserve formatting.
				if ([chunk length] > 0 && [chunk characterAtIndex:0] == ' ') {
					[chunk replaceCharactersInRange:NSMakeRange(0, 1)
										 withString:@"&nbsp;"];
					fullRange.length += 5;
				}
	
				/* Replace all remaining blocks of "  " (<space><space>) with " &nbsp;" (<space><&nbsp;>) so that
				 * formatting of large blocks of spaces in the middle of a line is preserved,
				 * and so WebKit properly line-wraps.
				 */
				[chunk replaceOccurrencesOfString:@"  "
									   withString:@" &nbsp;"
										  options:NSLiteralSearch
											range:fullRange];
			}

			
			/* If we need to encode non-ASCII to HTML, append string character by
			 * character, replacing any non-ascii characters with the designated SGML escape sequence.
			 */
			if (thingsToInclude.nonASCII) {
				unsigned length = [chunk length];
				for (unsigned i = 0; i < length; i++) {
					unichar currentChar = [chunk characterAtIndex:i];
					if (currentChar < 32) {
						//Control character.
						[string appendFormat:@"&#x%x;", currentChar];

					} else if (currentChar >= 127) {
						if (!UCIsSurrogateHighCharacter(currentChar)) {
							[string appendFormat:@"&#x%x;", currentChar];

						} else {
							//currentChar is the high character of a surrogate pair.
							unichar lowSurrogate = 0xFFFF;
							if ((i + 1) < length) {
								lowSurrogate = [chunk characterAtIndex:++i];
							}

							if (!UCIsSurrogateLowCharacter(lowSurrogate)) {
								//In case you're wondering: 0xFFFF is not a low surrogate. (Nor anything else, for that matter.)
								AILog(@"AIHTMLDecoder: Got high surrogate of surrogate pair, but there's no low surrogate after it. This is at index %u of chunk with length %u. The chunk is: %@", i, length, chunk);

							} else {
								UnicodeScalarValue codePoint = UCGetUnicodeScalarValueForSurrogatePair(/*highSurrogate*/ currentChar, lowSurrogate);
								[string appendFormat:@"&#x%x;", codePoint];
							}
						}

					} else if (currentChar == '\r') {
						/* \r\n is a single line break, so encode it as such. If we have an \r followed by a \n,
						 * skip the \n
						 */
						if ((i + 1 < length) && ([chunk characterAtIndex:(i+1)] == '\n')) {
							i++;
						}
						[string appendString:@"<BR>"];
						
					} else if (currentChar == '\n') {
						[string appendString:@"<BR>"];
						
					} else {
						//unichar characters may have a length of up to 3; be careful to get the whole character
						NSRange composedCharRange = [chunk rangeOfComposedCharacterSequenceAtIndex:i];
						[string appendString:[chunk substringWithRange:composedCharRange]];
						i += composedCharRange.length - 1;
					}
				}

			} else {
				replacements = [chunk replaceOccurrencesOfString:@"\r\n"
									   withString:@"<BR>"
										  options:NSLiteralSearch 
											range:fullRange];
				fullRange.length += (replacements * 2);

				replacements = [chunk replaceOccurrencesOfString:@"\r"
									   withString:@"<BR>"
										  options:NSLiteralSearch 
											range:fullRange];
				fullRange.length += (replacements * 3);

				replacements = [chunk replaceOccurrencesOfString:@"\n"
									   withString:@"<BR>"
										  options:NSLiteralSearch
											range:fullRange];
//				fullRange.length += (replacements * 3);

				[string appendString:chunk];
			}

			//Release the chunk
			[chunk release];
		}

		searchRange.location += searchRange.length;
	}

	[currentFamily release];
	[currentColor release];

	//Finish off the HTML
	if (thingsToInclude.styleTags) {
		if (currentItalic)        [string appendString:@"</I>"];
		if (currentBold)          [string appendString:@"</B>"];
		if (currentUnderline)     [string appendString:@"</U>"];
		if (currentStrikethrough) [string appendString:@"</S>"];
	}
	
	//If we had a link on the last pass, close the link tag
	if (oldLink) {
		//Close Link
		[string appendString:@"</a>"];
		oldLink = nil;
	}

	if (thingsToInclude.fontTags && thingsToInclude.closingFontTags && openFontTag) {
		//Close any open font tag
		[string appendString:@"</FONT>"];
	}
	if (rightToLeft) {
		//Close any open div
		[string appendString:@"</DIV>"];
	}
	if (thingsToInclude.headers && pageColor) {
		//Close the body tag
		[string appendString:@"</BODY>"];
	}
	if (thingsToInclude.headers) {
		//Close the HTML
		[string appendString:@"</HTML>"];
	}
	
	//KBOTC's odd hackish body background thingy for WMV since no one else will add it
	if (thingsToInclude.bodyBackground &&
	   (messageLength > 0)) {
		[string setString:@""];
		if ((pageColor = [inMessage attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil])) {
			[string setString:[pageColor hexString]];
			[string replaceOccurrencesOfString:@"\"" 
									withString:@"" 
									   options:NSLiteralSearch
										 range:NSMakeRange(0, [string length])];
		}
	}

	return string;
}

- (AIXMLElement *)elementWithAppKitAttributes:(NSDictionary *)attributes attributeNames:(NSSet *)attributeNames elementContent:(NSMutableString *)elementContent shouldAddElementContentToTopElement:(out BOOL *)outAddElementContentToTopElement
{
	if (!(attributes && [attributes count] && attributeNames && [attributeNames count]))
		return nil;

	attributes = [attributes dictionaryWithIntersectionWithSetOfKeys:attributeNames];

	NSString         *linkValue       = [attributes objectForKey:NSLinkAttributeName];
	NSTextAttachment *attachmentValue = [attributes objectForKey:NSAttachmentAttributeName];

	NSString *elementName = linkValue ? @"a" : @"span";
	BOOL moreThanJustAnImage = [attributes count] - (attachmentValue != nil);

	BOOL addElementContentToTopElement = YES;
	AIXMLElement *thisElement = moreThanJustAnImage ? [AIXMLElement elementWithNamespaceName:XMLNamespace elementName:elementName] : nil;
	if (linkValue) {
		[thisElement setValue:linkValue forAttribute:@"href"];
	}

	if (attachmentValue) {
		AITextAttachmentExtension *extension = (AITextAttachmentExtension *)attachmentValue;
		if ((thingsToInclude.attachmentTextEquivalents ||
			([extension respondsToSelector:@selector(shouldAlwaysSendAsText)] && [extension shouldAlwaysSendAsText])) &&
			([extension respondsToSelector:@selector(string)])) {
			[elementContent setString:[extension string]];
#if 0
		} else {
			/*XXX This doesn't work yet, and I have no interest in fixing it because nothing that receives the output from this method will have any use for the images.
			*It's not known whether any XHTML-IM clients support data: URLs, and the logs probably will not retain images either.
			*Feel free to hack on this if you find something that will want images.
			*I would recommend allocating a bit from the bitfield to control it, though.
			*--boredzo
			*
			*The log viewer now uses the output of this method and definitely does have use for images :)
			*/
			AIXMLElement *imageElement = [AIXMLElement elementWithNamespaceName:XMLNamespace elementName:@"img"];
			[imageElement setSelfCloses:YES];

			NSTextAttachmentCell *cell = (NSTextAttachmentCell *)[attachmentValue attachmentCell];
			NSSize size = [cell cellSize];
			[imageElement setValue:[NSNumber numberWithFloat:size.width] forAttribute:@"width"];
			[imageElement setValue:[NSNumber numberWithFloat:size.height] forAttribute:@"height"];

			NSString *path = [[attachmentValue fileWrapper] filename];
			//XXX If !path, write the image to the save path passed to -encodeStrictXHTML:imagesPath:.
			if (path) {
				NSURL *fileURL = [NSURL fileURLWithPath:path];
				[imageElement setValue:fileURL forAttribute:@"src"];
			}

			if (elementContent && [elementContent length]) {
				[imageElement setValue:elementContent forAttribute:@"alt"];
			}

			if (thisElement) {
				[thisElement addObject:imageElement];
			} else {
				thisElement = imageElement;
			}

			addElementContentToTopElement = NO;
#endif
		}
	}

	NSString *CSSString = [NSAttributedString CSSStringForTextAttributes:attributes];
	if (CSSString && [CSSString length]) {
		[thisElement setValue:CSSString forAttribute:@"style"];
	}

	if (outAddElementContentToTopElement) {
		*outAddElementContentToTopElement = addElementContentToTopElement;
	}

	return thisElement;
}
- (NSDictionary *)attributesByReplacingNSFontAttributeNameWithAIFontAttributeNames:(NSDictionary *)attributes
{
	NSFont *font = [[attributes objectForKey:NSFontAttributeName] retain];
	if (!font) {
		return [[attributes retain] autorelease];
	} else {
		NSMutableDictionary *mutableAttributes = [attributes mutableCopy];

		[mutableAttributes removeObjectForKey:NSFontAttributeName];

		[mutableAttributes setObject:[font familyName]
		                      forKey:AIFontFamilyAttributeName];
		[mutableAttributes setObject:[NSString stringWithFormat:@"%@pt", [NSString stringWithFloat:[font pointSize] maxDigits:2]]
		                      forKey:AIFontSizeAttributeName];

		NSFontTraitMask traits = [[NSFontManager sharedFontManager] traitsOfFont:font];
		if (traits & NSBoldFontMask) {
			[mutableAttributes setObject:@"bold" forKey:AIFontWeightAttributeName];
		}
		if (traits & NSItalicFontMask) {
			[mutableAttributes setObject:@"italic" forKey:AIFontStyleAttributeName];
		}

		[font release];

		NSDictionary *result = [NSDictionary dictionaryWithDictionary:mutableAttributes];
		[mutableAttributes release];
		return result;
	}
}

- (AIXMLElement *)rootStrictXHTMLElementForAttributedString:(NSAttributedString *)inMessage imagesPath:(NSString *)imagesSavePath
{
	NSRange			 searchRange;

	//Setup the incoming message as a regular string, and get its length
	NSString		*inMessageString = [inMessage string];
	unsigned		 messageLength = [inMessageString length];

	NSSet *emptySet = [NSSet set];

	//These two stacks are parallel. For every element, there should be a set of attribute names, and vice versa.
	NSMutableArray *elementStack = [NSMutableArray array];
	NSMutableArray *attributeNamesStack = [NSMutableArray array];

	//Root element: includeHeaders ? <html> : <div>

	if (thingsToInclude.headers) {
		[elementStack addObject:[AIXMLElement elementWithNamespaceName:XMLNamespace elementName:@"html"]];
		[attributeNamesStack addObject:emptySet];

		AIXMLElement *bodyElement = [AIXMLElement elementWithNamespaceName:XMLNamespace elementName:@"body"];
		[[elementStack lastObject] addObject:bodyElement];
		[elementStack addObject:bodyElement];
		[attributeNamesStack addObject:emptySet];

		NSColor *pageColor;
		if ((messageLength > 0) &&
		   (pageColor = [inMessage attribute:AIBodyColorAttributeName
									 atIndex:0
							  effectiveRange:NULL]))
		{
			[bodyElement setValue:[@"background-color: " stringByAppendingString:[pageColor CSSRepresentation]] forAttribute:@"style"];
		}
	}

	AIXMLElement *divElement = [AIXMLElement elementWithNamespaceName:XMLNamespace elementName:@"div"];
	//If the text is right-to-left, enclose all our HTML in an rtl div tag
	if ((messageLength > 0) &&
		([[inMessage attribute:NSParagraphStyleAttributeName
					   atIndex:0
				effectiveRange:nil] baseWritingDirection] == NSWritingDirectionRightToLeft))
	{
		[divElement setValue:@"rtl" forAttribute:@"dir"];
	}
	[[elementStack lastObject] addObject:divElement];
	[elementStack addObject:divElement];
	[attributeNamesStack addObject:emptySet];

	NSMutableSet *CSSCapableAttributes = [[NSAttributedString CSSCapableAttributesSet] mutableCopy];
	[CSSCapableAttributes addObject:NSLinkAttributeName];
	NSSet *CSSCapableAttributesWithNoAttachment = [NSSet setWithSet:CSSCapableAttributes];
	[CSSCapableAttributes addObject:NSAttachmentAttributeName];

	NSDictionary *prevAttributes = nil;
	//Loop through the entire string, handling each attribute run.
	searchRange = NSMakeRange(0,messageLength);
	while (searchRange.location < messageLength) {
		NSRange runRange;
		NSDictionary *attributes = [self attributesByReplacingNSFontAttributeNameWithAIFontAttributeNames:[inMessage attributesAtIndex:searchRange.location longestEffectiveRange:&runRange inRange:searchRange]];
		attributes = [attributes dictionaryWithIntersectionWithSetOfKeys:CSSCapableAttributes];

		NSSet *startedKeys = nil, *endedKeys = nil;
		[attributes compareWithPriorDictionary:prevAttributes
		                          getAddedKeys:&startedKeys
		                        getRemovedKeys:&endedKeys
		                    includeChangedKeys:YES];
		prevAttributes = [attributes dictionaryWithIntersectionWithSetOfKeys:CSSCapableAttributesWithNoAttachment];
		if([attributes objectForKey:NSAttachmentAttributeName] != nil)
			runRange.length = 1;  //Encode a single image at a time

		NSMutableSet *mutableEndedKeys = [endedKeys mutableCopy];
		if (mutableEndedKeys) {
			//First handle attributes that have ended or changed.
			if ([mutableEndedKeys count]) {
				NSMutableSet *attributesToRestore = [NSMutableSet set];
				NSRange popRange = { [attributeNamesStack count], 0 };
				while ([mutableEndedKeys count]) {
					--popRange.location; ++popRange.length;

					NSMutableSet *attributeNames = [attributeNamesStack objectAtIndex:popRange.location];
					NSSet *intersection = [attributeNames intersectionWithSet:mutableEndedKeys];

					[attributeNames minusSet:intersection];
					[attributesToRestore unionSet:attributeNames];

					[mutableEndedKeys minusSet:intersection];
				}
				[attributeNamesStack removeObjectsInRange:popRange];
				[elementStack removeObjectsInRange:popRange];

				//Push a new element to restore any attributes that haven't ended.
				//If no attributes need to be restored, then we do nothing.
				//If there are attributes to be restored but they're not in the attributes dictionary, then they have in fact ended, and are thus excluded from restoration by the call to -dictionaryWithIntersectionWithSetOfKeys:.
				if (attributesToRestore && [attributesToRestore count]) {
					AIXMLElement *restoreElement = [self elementWithAppKitAttributes:[attributes dictionaryWithIntersectionWithSetOfKeys:attributesToRestore]
					                                                  attributeNames:attributesToRestore
					                                                  elementContent:nil
					                             shouldAddElementContentToTopElement:NULL];
					[[elementStack lastObject] addObject:restoreElement];
					[elementStack addObject:restoreElement];

					[attributeNamesStack addObject:attributesToRestore];
				}
			}

			[mutableEndedKeys release];
		}

		//Now handle attributes that have started or changed.
		NSMutableString *elementContent = [[[inMessageString substringWithRange:runRange] mutableCopy] autorelease];
		
		BOOL addElementContentToTopElement;
		if ([startedKeys count]) {
			//Sort the keys by the length of their range.
			//First, we build a list of [length, attribute-name] arrays.
			NSMutableArray *startedKeysArray = [[startedKeys allObjects] mutableCopy];
			for (unsigned i = 0, count = [startedKeysArray count]; i < count; ++i) {
				NSRange attributeRange;
				NSString *attributeName = [startedKeysArray objectAtIndex:i];
				[inMessage  attribute:attributeName
				              atIndex:searchRange.location
				longestEffectiveRange:&attributeRange
				              inRange:searchRange];

				NSMutableArray *item = [[NSMutableArray alloc] initWithCapacity:2];
				[item addObject:[NSNumber numberWithUnsignedInt:attributeRange.length]];
				[item addObject:attributeName];
				[startedKeysArray replaceObjectAtIndex:i withObject:item];
				[item release];
			}
			//Sort. Items will be sorted first by length, then by attribute name.
			[startedKeysArray sortUsingSelector:@selector(compare:)];

			//Consolidate keys by length.
			for (unsigned i = 0, count = [startedKeysArray count]; i < count; ++i) {
				NSMutableSet *itemKeys = [NSMutableSet setWithCapacity:1];
				[itemKeys addObject:[[startedKeysArray objectAtIndex:i] objectAtIndex:1]];

				//Eat any equal keys that follow.
				unsigned j = i + 1;
				while (
					(j < count)
				&&	([[[startedKeysArray objectAtIndex:i] objectAtIndex:0] unsignedIntValue] == [[[startedKeysArray objectAtIndex:j] objectAtIndex:0] unsignedIntValue])
				) {
					[itemKeys addObject:[[startedKeysArray objectAtIndex:j] objectAtIndex:1]];
					[startedKeysArray removeObjectAtIndex:j];
					--count;
				}

				[[startedKeysArray objectAtIndex:i] replaceObjectAtIndex:1 withObject:itemKeys];
			}

			//Turn each consolidated bunch of keys into an element.
			addElementContentToTopElement = NO;

			NSEnumerator *startedKeysEnum = [startedKeysArray objectEnumerator];
			NSArray *item;
			while ((item = [startedKeysEnum nextObject])) {
				NSSet *itemKeys = [item objectAtIndex:1];

				//Only the last value of addElementContentToTopElement matters here, since we're adding elements to the stack, and that flag relates to the top element.
				AIXMLElement *thisElement = [self elementWithAppKitAttributes:attributes
															   attributeNames:itemKeys
															   elementContent:elementContent
										  shouldAddElementContentToTopElement:&addElementContentToTopElement];
				if (thisElement) {
					[[elementStack lastObject] addObject:thisElement];
					[attributeNamesStack addObject:itemKeys];
					[elementStack addObject:thisElement];
				} else if(!addElementContentToTopElement) {
					[[elementStack lastObject] addObject:elementContent];
				}
			}
			[startedKeysArray release];

		} else {
			addElementContentToTopElement = YES;
		}

		if (addElementContentToTopElement) {
			//Insert an empty BR element between every pair of lines.
			AIXMLElement *brElement = [AIXMLElement elementWithNamespaceName:XMLNamespace elementName:@"br"];
			[brElement setSelfCloses:YES];
			NSArray *linesAndBRs = [elementContent allLinesWithSeparator:brElement];

			//Add these zero or more lines, with BRs between them, to the top element on the stack.
			[[elementStack lastObject] addObjectsFromArray:linesAndBRs];
		}

		searchRange.location += runRange.length;
		searchRange.length   -= runRange.length;
	}

	return [elementStack objectAtIndex:0];
}

- (NSString *)encodeStrictXHTML:(NSAttributedString *)inMessage imagesPath:(NSString *)imagesSavePath
{
	NSString *output = [[self rootStrictXHTMLElementForAttributedString:inMessage imagesPath:imagesSavePath] XMLString];
	if (thingsToInclude.headers) {
		NSString *doctype = @"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">";
		output = [doctype stringByAppendingString:output];
	}
	return output;
}

- (NSString *)encodeHTML:(NSAttributedString *)inMessage imagesPath:(NSString *)imagesSavePath
{
	return thingsToInclude.generateStrictXHTML ? [self encodeStrictXHTML:inMessage imagesPath:imagesSavePath] : [self encodeLooseHTML:inMessage imagesPath:imagesSavePath];
}

- (NSAttributedString *)decodeHTML:(NSString *)inMessage
{
	return [self decodeHTML:inMessage withDefaultAttributes:nil];
}

- (NSAttributedString *)decodeHTML:(NSString *)inMessage withDefaultAttributes:(NSDictionary *)inDefaultAttributes
{
	NSScanner					*scanner;
	static NSCharacterSet		*tagCharStart = nil, *tagEnd = nil, *charEnd = nil, *absoluteTagEnd = nil;
	NSString					*chunkString, *tagOpen;
	NSMutableAttributedString	*attrString;
	AITextAttributes			*textAttributes;
	
	//Reset the div and span ivars
	send = NO;
	receive = NO;
	inDiv = NO;
	inLogSpan = NO;

    //set up
	if (inDefaultAttributes) {
		textAttributes = [AITextAttributes textAttributesWithDictionary:inDefaultAttributes];
	} else {
		textAttributes = [[_defaultTextDecodingAttributes copy] autorelease];
	}
	
    attrString = [[NSMutableAttributedString alloc] init];

	if (!tagCharStart)     tagCharStart = [[NSCharacterSet characterSetWithCharactersInString:@"<&"] retain];
	if (!tagEnd)                 tagEnd = [[NSCharacterSet characterSetWithCharactersInString:@" >"] retain];
	if (!charEnd)               charEnd = [[NSCharacterSet characterSetWithCharactersInString:@";"] retain];
	if (!absoluteTagEnd) absoluteTagEnd = [[NSCharacterSet characterSetWithCharactersInString:@">"] retain];

	scanner = [NSScanner scannerWithString:inMessage];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

	//Parse the HTML
	while (![scanner isAtEnd]) {
		/*
		 * Scan up to an HTML tag or escaped character.
		 *
		 * All characters before the next HTML entity are textual characters in the current textAttributes. We append
		 * those characters to our final attributed string with the desired attributes before continuing.
		 */
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if ([scanner scanUpToCharactersFromSet:tagCharStart intoString:&chunkString]) {
			id	languageValue = [textAttributes languageValue];
			
			/* AIM sets language value 143 for characters which are in Symbol, Wingdings, or Webdings.
			 * All Symbol characters can be represented in the Symbol font. When the language value is 143, they are being sent
			 * as normal ASCII characters and we must run them through stringByConvertingSymbolToSymbolUnicode.
			 *
			 * Wingdings characters can be represented in the font Wingdings, if available, by offsetting the ASCII characters
			 * by 0xF000 to move into the Private  Use space.  If the font is not available, many of them can be represented
			 * in any font via our stringByConvertingWingdingsToUnicode conversion table. Wingdings2 and Wingdings3 do not have
			 * conversion tables but can also be used as fonts so long as we move the ASCII characters to the Private Use space.
			 *
			 * Similarly, Webdings can be represented in the font Webdings in the Private Use unicode space.
			 */
			if (languageValue && ([languageValue intValue] == 143)) {
				NSString *fontFamily = [textAttributes fontFamily];

				if ([fontFamily caseInsensitiveCompare:@"Symbol"] == NSOrderedSame) {
					chunkString = [chunkString stringByConvertingSymbolToSymbolUnicode];

				} else if ([fontFamily rangeOfString:@"Wingdings" options:NSCaseInsensitiveSearch].location != NSNotFound) {
					if ([NSFont fontWithName:fontFamily size:0]) {
						//Use the font (in is Private Use space) if it is installed
						chunkString = [chunkString stringByTranslatingByOffset:0xF000];

					} else {
						chunkString = [chunkString stringByConvertingWingdingsToUnicode];
					}

				} else if ([fontFamily rangeOfString:@"Webdings" options:NSCaseInsensitiveSearch].location != NSNotFound) {
					if ([NSFont fontWithName:fontFamily size:0]) {
						//Use the Webdings font if it is installed
						chunkString = [chunkString stringByTranslatingByOffset:0xF000];
					}						
				}
			}
			
			[attrString appendString:chunkString withAttributes:[textAttributes dictionary]];
		}
		
		//Process the tag
		if ([scanner scanCharactersFromSet:tagCharStart intoString:&tagOpen]) { //If a tag wasn't found, we don't process.
			unsigned scanLocation = [scanner scanLocation]; //Remember our location (if this is an invalid tag we'll need to move back)

			if ([tagOpen isEqualToString:@"<"]) { // HTML <tag>
				BOOL		validTag = [scanner scanUpToCharactersFromSet:tagEnd intoString:&chunkString]; //Get the tag
				NSString	*charactersToSkipAfterThisTag = nil;

				if (validTag) { 
					//HTML
					if ([chunkString caseInsensitiveCompare:@"HTML"] == NSOrderedSame) {
						//We ignore most stuff inside the HTML tag, but don't want to see the end of it.
						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];
	
					} else if ([chunkString caseInsensitiveCompare:@"/HTML"] == NSOrderedSame) {
						//We are done
						break;

					//PRE -- ignore attributes for logViewer
					} else if ([chunkString caseInsensitiveCompare:@"PRE"] == NSOrderedSame ||
							 [chunkString caseInsensitiveCompare:@"/PRE"] == NSOrderedSame) {

						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];

						[textAttributes setTextColor:[NSColor blackColor]];

					//DIV
					} else if ([chunkString caseInsensitiveCompare:@"DIV"] == NSOrderedSame) {
						if ([scanner scanUpToCharactersFromSet:absoluteTagEnd
													intoString:&chunkString]) {
							[self processDivTagArgs:[self parseArguments:chunkString] attributes:textAttributes];
						}
						inDiv = YES;

					} else if ([chunkString caseInsensitiveCompare:@"/DIV"] == NSOrderedSame) {
						inDiv = NO;

					//LINK
					} else if ([chunkString caseInsensitiveCompare:@"A"] == NSOrderedSame) {
						//[textAttributes setUnderline:YES];
						//[textAttributes setTextColor:[NSColor blueColor]];
						if ([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]) {
							[self processLinkTagArgs:[self parseArguments:chunkString] 
										  attributes:textAttributes]; //Process the linktag's contents
						}

					} else if ([chunkString caseInsensitiveCompare:@"/A"] == NSOrderedSame) {
						[textAttributes setLinkURL:nil];

					//Body
					} else if ([chunkString caseInsensitiveCompare:@"BODY"] == NSOrderedSame) {
						if ([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]) {
							[self processBodyTagArgs:[self parseArguments:chunkString] attributes:textAttributes]; //Process the font tag's contents
						}

					} else if ([chunkString caseInsensitiveCompare:@"/BODY"] == NSOrderedSame) {
						//ignore

					//Font
					} else if ([chunkString caseInsensitiveCompare:@"FONT"] == NSOrderedSame) {
						if ([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]) {
							//Process the font tag's contents
							[self processFontTagArgs:[self parseArguments:chunkString] attributes:textAttributes];
						}

					} else if ([chunkString caseInsensitiveCompare:@"/FONT"] == NSOrderedSame) {
						[textAttributes resetFontAttributes];
						
					//span
					} else if ([chunkString caseInsensitiveCompare:@"SPAN"] == NSOrderedSame) {
						if ([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]) {
							[self processSpanTagArgs:[self parseArguments:chunkString] attributes:textAttributes];
						}

					} else if ([chunkString caseInsensitiveCompare:@"/SPAN"] == NSOrderedSame) {
						if (inLogSpan) {
							[textAttributes setTextColor:[NSColor blackColor]];
							[textAttributes setFontFamily:@"Helvetica"];
							[textAttributes setFontSize:12];
							inLogSpan = NO;
						}
						
					//Line Break
					} else if ([chunkString caseInsensitiveCompare:@"BR"] == NSOrderedSame || 
							 [chunkString caseInsensitiveCompare:@"BR/"] == NSOrderedSame ||
							 [chunkString caseInsensitiveCompare:@"/BR"] == NSOrderedSame) {
						[attrString appendString:@"\n" withAttributes:nil];
						
						/* Make sure the tag closes; it may have a <BR /> which stopped the scanner at
						 * at the space rather than the '>'
						 */
						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];

						/* Skip any newlines following an HTML line break; if we have one we want to ignore the other.
						 * This is generally unnecessary; it is a hack around a winAIM bug where 
						 * newlines are sent as "<BR>\n\r"
						 */
						charactersToSkipAfterThisTag = @"\n\r";

					//Bold
					} else if ([chunkString caseInsensitiveCompare:@"B"] == NSOrderedSame) {
						[textAttributes enableTrait:NSBoldFontMask];
					} else if ([chunkString caseInsensitiveCompare:@"/B"] == NSOrderedSame) {
						[textAttributes disableTrait:NSBoldFontMask];

					//Strong (interpreted as bold)
					} else if ([chunkString caseInsensitiveCompare:@"STRONG"] == NSOrderedSame) {
						[textAttributes enableTrait:NSBoldFontMask];
					} else if ([chunkString caseInsensitiveCompare:@"/STRONG"] == NSOrderedSame) {
						[textAttributes disableTrait:NSBoldFontMask];

					//Italic
					} else if ([chunkString caseInsensitiveCompare:@"I"] == NSOrderedSame) {
						[textAttributes enableTrait:NSItalicFontMask];
					} else if ([chunkString caseInsensitiveCompare:@"/I"] == NSOrderedSame) {
						[textAttributes disableTrait:NSItalicFontMask];

					//Emphasised (interpreted as italic)
					} else if ([chunkString caseInsensitiveCompare:@"EM"] == NSOrderedSame) {
						[textAttributes enableTrait:NSItalicFontMask];
					} else if ([chunkString caseInsensitiveCompare:@"/EM"] == NSOrderedSame) {
						[textAttributes disableTrait:NSItalicFontMask];

					//Underline
					} else if ([chunkString caseInsensitiveCompare:@"U"] == NSOrderedSame) {
						[textAttributes setUnderline:YES];
					} else if ([chunkString caseInsensitiveCompare:@"/U"] == NSOrderedSame) {
						[textAttributes setUnderline:NO];

					//Strikethrough: <s> is deprecated, but people use it
					} else if ([chunkString caseInsensitiveCompare:@"S"] == NSOrderedSame) {
						[textAttributes setStrikethrough:YES];
					} else if ([chunkString caseInsensitiveCompare:@"/S"] == NSOrderedSame) {
						[textAttributes setStrikethrough:NO];

					// Subscript
					} else if ([chunkString caseInsensitiveCompare:@"SUB"] == NSOrderedSame)  {
						[textAttributes setSubscript:YES];
					} else if ([chunkString caseInsensitiveCompare:@"/SUB"] == NSOrderedSame)  {
						[textAttributes setSubscript:NO];

					// Superscript
					} else if ([chunkString caseInsensitiveCompare:@"SUP"] == NSOrderedSame)  {
						[textAttributes setSuperscript:YES];
					} else if ([chunkString caseInsensitiveCompare:@"/SUP"] == NSOrderedSame)  {
						[textAttributes setSuperscript:NO];

					//Image
					} else if ([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame) {
						if ([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]) {
							NSAttributedString *attachString = [self processImgTagArgs:[self parseArguments:chunkString] 
																			attributes:textAttributes];
							if (attachString) {
								[attrString appendAttributedString:attachString];
							}
						}
					} else if ([chunkString caseInsensitiveCompare:@"/IMG"] == NSOrderedSame) {
						//just ignore </img> if we find it

					//Horizontal Rule
					} else if ([chunkString caseInsensitiveCompare:@"HR"] == NSOrderedSame) {
						[attrString appendString:horizontalRule withAttributes:nil];
						
					// Ignore <p> for those wacky AIM express users
					} else if ([chunkString caseInsensitiveCompare:@"P"] == NSOrderedSame ||
							   ([chunkString caseInsensitiveCompare:@"/P"] == NSOrderedSame)) {
						
					// Ignore <head> tags
					} else if ([chunkString caseInsensitiveCompare:@"HEAD"] == NSOrderedSame ||
							   ([chunkString caseInsensitiveCompare:@"/HEAD"] == NSOrderedSame)) {
						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];
						
					// Ignore <meta> tags
					} else if ([chunkString caseInsensitiveCompare:@"META"] == NSOrderedSame ||
							   ([chunkString caseInsensitiveCompare:@"/META"] == NSOrderedSame)) {
						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];
						
					//Invalid
					} else {
						validTag = NO;
					}
				}

				//Skip over the end tag character '>' and any other characters we want to skip
				if (validTag) {
					//Get to the > if we're not there already, as will happen with XML namespacing...
					[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:NULL];

					//And skip it
					if (![scanner isAtEnd]) {
						[scanner setScanLocation:[scanner scanLocation]+1];
						
						//Skip any other characters we are supposed to skip before continuing
						if (charactersToSkipAfterThisTag) {
							NSCharacterSet *charSetToSkip;
							
							charSetToSkip = [NSCharacterSet characterSetWithCharactersInString:charactersToSkipAfterThisTag];
							[scanner scanCharactersFromSet:charSetToSkip
												intoString:NULL];
						}
					}
					
				} else {
					//When an invalid tag is encountered, we add the <, and then move our scanner back to continue processing
					[attrString appendString:@"<" withAttributes:[textAttributes dictionary]];
					[scanner setScanLocation:scanLocation];
				}

			} else if ([tagOpen compare:@"&"] == NSOrderedSame) { // escape character, eg &gt;
				BOOL validTag = [scanner scanUpToCharactersFromSet:charEnd intoString:&chunkString];

				if (validTag) {
					// We could upgrade this to use an NSDictionary with lots of chars
					// but for now, if-blocks will do
					if ([chunkString caseInsensitiveCompare:@"GT"] == NSOrderedSame) {
						[attrString appendString:@">" withAttributes:[textAttributes dictionary]];

					} else if ([chunkString caseInsensitiveCompare:@"LT"] == NSOrderedSame) {
						[attrString appendString:@"<" withAttributes:[textAttributes dictionary]];

					} else if ([chunkString caseInsensitiveCompare:@"AMP"] == NSOrderedSame) {
						[attrString appendString:@"&" withAttributes:[textAttributes dictionary]];

					} else if ([chunkString caseInsensitiveCompare:@"QUOT"] == NSOrderedSame) {
						[attrString appendString:@"\"" withAttributes:[textAttributes dictionary]];

					} else if ([chunkString caseInsensitiveCompare:@"APOS"] == NSOrderedSame) {
						[attrString appendString:@"'" withAttributes:[textAttributes dictionary]];

					} else if ([chunkString caseInsensitiveCompare:@"NBSP"] == NSOrderedSame) {
						[attrString appendString:@" " withAttributes:[textAttributes dictionary]];

					} else if ([chunkString hasPrefix:@"#x"]) {
						NSString *hexString = [chunkString substringFromIndex:2];
						NSScanner *hexScanner = [NSScanner scannerWithString:hexString];
						unsigned int character = 0;
						if([hexScanner scanHexInt:&character])
							[attrString appendString:[NSString stringWithFormat:@"%C", character]
									  withAttributes:[textAttributes dictionary]];
					} else if ([chunkString hasPrefix:@"#"]) {
						NSString *decString = [chunkString substringFromIndex:1];
						NSScanner *decScanner = [NSScanner scannerWithString:decString];
						int character = 0;
						if([decScanner scanInt:&character])
							[attrString appendString:[NSString stringWithFormat:@"%C", character]
									  withAttributes:[textAttributes dictionary]];
					}
					else { //Invalid
						validTag = NO;
					}
				}

				if (validTag) { //Skip over the end tag character ';'.  Don't scan all of that character, however, as we'll skip ;; and so on.
					if (![scanner isAtEnd])
						[scanner setScanLocation:[scanner scanLocation] + 1];
				} else {
					//When an invalid tag is encountered, we add the &, and then move our scanner back to continue processing
					[attrString appendString:@"&" withAttributes:[textAttributes dictionary]];
					[scanner setScanLocation:scanLocation];
				}
			} else { //Invalid tag character (most likely a stray < or &)
				if ([tagOpen length] > 1) {
					//If more than one character was scanned, add the first one, and move the scanner back to re-process the additional characters
					[attrString appendString:[tagOpen substringToIndex:1] withAttributes:[textAttributes dictionary]];
					[scanner setScanLocation:[scanner scanLocation] - ([tagOpen length]-1)]; 
				} else {
					[attrString appendString:tagOpen withAttributes:[textAttributes dictionary]];
				}
			}
		}
		[pool release];
	}
	
	/* If the string has a constant NSBackgroundColorAttributeName attribute and no AIBodyColorAttributeName,
	 * we want to move the NSBackgroundColorAttributeName attribute to AIBodyColorAttributeName (Things are a
	 * lot more attractive this way).
	 */
	if ([attrString length]) {
		NSRange backRange;
		NSColor *bodyColor = [attrString attribute:NSBackgroundColorAttributeName 
										   atIndex:0 
									effectiveRange:&backRange];
		if (bodyColor && (backRange.length == [attrString length])) {
			[attrString addAttribute:AIBodyColorAttributeName
							   value:bodyColor 
							   range:NSMakeRange(0,[attrString length])];
			[attrString removeAttribute:NSBackgroundColorAttributeName 
								  range:NSMakeRange(0,[attrString length])];
		}
	}

	return [attrString autorelease];
}

#pragma mark Tag-parsing

/*methods in this section take a parsed tag (see -parseArguments:) and transfer
 *  its specification to a text-attributes object.
 */

//Process the contents of a font tag
- (void)processFontTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;

	enumerator = [[inArgs allKeys] objectEnumerator];
	while ((arg = [enumerator nextObject])) {
		if ([arg caseInsensitiveCompare:@"face"] == NSOrderedSame) {
			[textAttributes setFontFamily:[inArgs objectForKey:arg]];

		} else if ([arg caseInsensitiveCompare:@"size"] == NSOrderedSame) {
			//Always prefer an ABSZ to a size
			if (![inArgs objectForKey:@"ABSZ"] && ![inArgs objectForKey:@"absz"]) {
				unsigned absSize = [[inArgs objectForKey:arg] intValue];
				static int pointSizes[] = { 9, 10, 12, 14, 18, 24, 48, 72 };
				int size = (absSize <= 8 ? pointSizes[absSize-1] : 12);
				
				[textAttributes setFontSize:size];
			}

		} else if ([arg caseInsensitiveCompare:@"absz"] == NSOrderedSame) {
			[textAttributes setFontSize:[[inArgs objectForKey:arg] intValue]];

		} else if ([arg caseInsensitiveCompare:@"color"] == NSOrderedSame) {
			[textAttributes setTextColor:[NSColor colorWithHTMLString:[inArgs objectForKey:arg] 
														 defaultColor:[NSColor blackColor]]];

		} else if ([arg caseInsensitiveCompare:@"back"] == NSOrderedSame) {
			[textAttributes setTextBackgroundColor:[NSColor colorWithHTMLString:[inArgs objectForKey:arg]
																   defaultColor:[NSColor whiteColor]]];

		} else if ([arg caseInsensitiveCompare:@"lang"] == NSOrderedSame) {
			[textAttributes setLanguageValue:[inArgs objectForKey:arg]];

		}  else if ([arg caseInsensitiveCompare:@"sender"] == NSOrderedSame) {
			//Ghetto HTML log processing
			if (inDiv && send) {
				[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0]];
			} else if (inDiv && receive) {
				[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.5 alpha:1.0]];
			}
		}
		
	}
}

- (void)processBodyTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;

	enumerator = [[inArgs allKeys] objectEnumerator];
	while ((arg = [enumerator nextObject])) {
		if ([arg caseInsensitiveCompare:@"bgcolor"] == NSOrderedSame) {
			[textAttributes setBackgroundColor:[NSColor colorWithHTMLString:[inArgs objectForKey:arg] defaultColor:[NSColor whiteColor]]];

		}	
	}
}

- (void)processSpanTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;
	
	enumerator = [[inArgs allKeys] objectEnumerator];
	while ((arg = [enumerator nextObject])) {
		if ([arg caseInsensitiveCompare:@"class"] == NSOrderedSame) {
			//Process the span tag if it's in a log
			NSString	*class = [inArgs objectForKey:arg];

			if ([class caseInsensitiveCompare:@"sender"] == NSOrderedSame) {
				if (inDiv && send) {
					[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 
																		   green:0.5
																			blue:0.0 
																		   alpha:1.0]];
					inLogSpan = YES;
				} else if (inDiv && receive) {
					[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0
																		   green:0.0
																			blue:0.5 
																		   alpha:1.0]];
					inLogSpan = YES;
				}

			} else if ([class caseInsensitiveCompare:@"timestamp"] == NSOrderedSame) {
				[textAttributes setTextColor:[NSColor grayColor]];
				inLogSpan = YES;
			}
		} else if ([arg caseInsensitiveCompare:@"style"] == NSOrderedSame) {
			NSString	*style = [inArgs objectForKey:arg];
			int			styleLength = [style length];
			NSRange		attributeRange;

			attributeRange = [style rangeOfString:@"font-family: " options:NSCaseInsensitiveSearch];
			if (attributeRange.location != NSNotFound) {
				NSRange	 nextSemicolon = [style rangeOfString:@";"
													  options:NSLiteralSearch
														range:NSMakeRange(attributeRange.location, styleLength - attributeRange.location)];
				if (nextSemicolon.location != NSNotFound) {
					NSString *fontFamily = [style substringWithRange:NSMakeRange(NSMaxRange(attributeRange),
																				 nextSemicolon.location - NSMaxRange(attributeRange))];
					
					[textAttributes setFontFamily:fontFamily];
				}
			}
			
			attributeRange = [style rangeOfString:@"font-size: " options:NSCaseInsensitiveSearch];
			if (attributeRange.location != NSNotFound) {
				NSRange	 nextSemicolon = [style rangeOfString:@";"
													  options:NSLiteralSearch
														range:NSMakeRange(attributeRange.location, styleLength - attributeRange.location)];
				if (nextSemicolon.location != NSNotFound) {
					NSString *fontSize = [style substringWithRange:NSMakeRange(NSMaxRange(attributeRange), nextSemicolon.location - NSMaxRange(attributeRange))];
					
					static int stylePointSizes[] = { 9, 10, 12, 14, 18, 24 };
					int size = 12;
					
					if ([fontSize caseInsensitiveCompare:@"xx-small"] == NSOrderedSame) {
						size = stylePointSizes[0];
						
					} else if ([fontSize caseInsensitiveCompare:@"x-small"] == NSOrderedSame) {
						size = stylePointSizes[1];
						
					} else if ([fontSize caseInsensitiveCompare:@"small"] == NSOrderedSame) {
						size = stylePointSizes[2];
						
					} else if ([fontSize caseInsensitiveCompare:@"medium"] == NSOrderedSame) {
						size = stylePointSizes[3];
						
					} else if ([fontSize caseInsensitiveCompare:@"large"] == NSOrderedSame) {
						size = stylePointSizes[4];
						
					} else if ([fontSize caseInsensitiveCompare:@"x-large"] == NSOrderedSame) {
						size = stylePointSizes[5];
					}
					
					[textAttributes setFontSize:size];
				}
			}

			attributeRange = [style rangeOfString:@"font: " options:NSCaseInsensitiveSearch];
			if (attributeRange.location != NSNotFound) {
				NSRange	 nextSemicolon = [style rangeOfString:@";"
													  options:NSLiteralSearch
														range:NSMakeRange(attributeRange.location, styleLength - attributeRange.location)];
				if (nextSemicolon.location != NSNotFound) {
					NSString *fontString = [style substringWithRange:NSMakeRange(NSMaxRange(attributeRange),
																				 nextSemicolon.location - NSMaxRange(attributeRange))];
					
                    NSScanner *fontStringScanner = [NSScanner scannerWithString:fontString];
                    float fontSize;
                    if([fontStringScanner scanFloat:&fontSize])
                        [textAttributes setFontSize:fontSize];
                    [fontStringScanner scanUpToString:@" " intoString:nil];
                    [fontStringScanner setScanLocation:[fontStringScanner scanLocation] + 1];
                    NSString *font = [fontString substringFromIndex:[fontStringScanner scanLocation]];
                    if([font length])
                        [textAttributes setFontFamily:font];
				}
			}

			attributeRange = [style rangeOfString:@"color: " options:NSCaseInsensitiveSearch];
			if (attributeRange.location != NSNotFound) {
				NSRange	 nextSemicolon = [style rangeOfString:@";" options:NSLiteralSearch range:NSMakeRange(attributeRange.location, styleLength - attributeRange.location)];
				if (nextSemicolon.location != NSNotFound) {
					NSString *hexColor = [style substringWithRange:NSMakeRange(NSMaxRange(attributeRange), nextSemicolon.location - NSMaxRange(attributeRange))];
					
					[textAttributes setTextColor:[NSColor colorWithHTMLString:hexColor
																 defaultColor:[NSColor blackColor]]];
				}
			}

            attributeRange = [style rangeOfString:@"background-color: " options:NSCaseInsensitiveSearch];
			if (attributeRange.location != NSNotFound) {
				NSRange	 nextSemicolon = [style rangeOfString:@";" options:NSLiteralSearch range:NSMakeRange(attributeRange.location, styleLength - attributeRange.location)];
				if (nextSemicolon.location != NSNotFound) {
					NSString *hexColor = [style substringWithRange:NSMakeRange(NSMaxRange(attributeRange), nextSemicolon.location - NSMaxRange(attributeRange))];
					
					[textAttributes setBackgroundColor:[NSColor colorWithHTMLString:hexColor
																	   defaultColor:[NSColor blackColor]]];
				}
			}
        }
	}
}

- (void)processLinkTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;

	enumerator = [[inArgs allKeys] objectEnumerator];
	while ((arg = [enumerator nextObject])) {
		if ([arg caseInsensitiveCompare:@"href"] == NSOrderedSame) {
			NSString	*linkString = [inArgs objectForKey:arg];
			
			/* Replace any AIM-specific %n occurances with their escaped version.
			 * Note: It seems like this would be a good place to use CFURLCreateStringByReplacingPercentEscapes()
			 * and then CFURLCreateStringByAddingPercentEscapes().  Unfortunately, CFURLCreateStringByReplacingPercentEscapes()
			 * returns NULL if any percent escapes are invalid... and %n is decidedly invalid.
			 */
			if ([linkString rangeOfString:@"%n"].location != NSNotFound) {
				NSMutableString	*newLinkString = [[linkString mutableCopy] autorelease];
				[newLinkString replaceOccurrencesOfString:@"%n"
											   withString:@"%25n"
												  options:NSLiteralSearch
													range:NSMakeRange(0, [newLinkString length])];
				linkString = newLinkString;
			}

			[textAttributes setLinkURL:[NSURL URLWithString:linkString]];
		}
	}
}

- (void)processDivTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;
	
	enumerator = [[inArgs allKeys] objectEnumerator];
	while ((arg = [enumerator nextObject])) {
		if ([arg caseInsensitiveCompare:@"dir"] == NSOrderedSame) {
			//Right to left, left to right handling
			NSString	*direction = [inArgs objectForKey:arg];
			
			if ([direction caseInsensitiveCompare:@"rtl"] == NSOrderedSame) {
				[textAttributes setWritingDirection:NSWritingDirectionRightToLeft];
				
			} else if ([direction caseInsensitiveCompare:@"ltr"] == NSOrderedSame) {
				[textAttributes setWritingDirection:NSWritingDirectionLeftToRight];
			}
			
		} else if ([arg caseInsensitiveCompare:@"class"] == NSOrderedSame) {
			NSString	*class = [inArgs objectForKey:arg];
			if ([class caseInsensitiveCompare:@"send"] == NSOrderedSame) {
				send = YES;
				receive = NO;
			} else if ([class caseInsensitiveCompare:@"receive"] == NSOrderedSame) {
				receive = YES;
				send = NO;
			} else if ([class caseInsensitiveCompare:@"status"] == NSOrderedSame) {
				[textAttributes setTextColor:[NSColor grayColor]];
			}
		}
	}
}

- (NSAttributedString *)processImgTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator				*enumerator;
	NSString					*arg;
	NSAttributedString			*attachString;
	AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];

	enumerator = [inArgs keyEnumerator];
	while ((arg = [enumerator nextObject])) {
		if ([arg caseInsensitiveCompare:@"src"] == NSOrderedSame) {
			NSString	*src = [inArgs objectForKey:arg];

			//The src may be a file:// style path; convert it to a system path via NSURL
			NSURL		*url = [NSURL URLWithString:src];
			if (url && [url isFileURL]) src = [url path];

			[attachment setPath:src];
		}
		if ([arg caseInsensitiveCompare:@"alt"] == NSOrderedSame) {
			[attachment setString:[inArgs objectForKey:arg]];
			[attachment setHasAlternate:YES];
		}
		if ([arg caseInsensitiveCompare:@"class"] == NSOrderedSame) {
			[attachment setImageClass:[inArgs objectForKey:arg]];
		}
	}
	
	[attachment setShouldSaveImageForLogging:YES];

	//Use the real image if possible
	NSImage		*image = [attachment image];
	
	//Otherwise, use an icon representing the image
	if (!image) image = [attachment iconImage];

	if (image) {
		NSTextAttachmentCell *cell = [[NSTextAttachmentCell alloc] initImageCell:image];
		[attachment setAttachmentCell:cell];
		[cell release];
		
		attachString = [NSAttributedString attributedStringWithAttachment:attachment];
		[attachment release];
	} else {
		attachString = nil;
	}

	return attachString;
}

//XXX - Currently always appends as png.  This is probably not always best as Windows DirectIM will not handle it.
- (BOOL)appendImage:(NSImage *)attachmentImage
			 atPath:(NSString *)inPath
		   toString:(NSMutableString *)string
		   withName:(NSString *)inName 
		 imageClass:(NSString *)imageClass
		 imagesPath:(NSString *)imagesPath
{	
	NSString	*shortFileName;
	BOOL		success = NO;

	if (imagesPath || !inPath) {
		//create the images directory if it doesn't exist
		if (imagesPath) {
			[[NSFileManager defaultManager] createDirectoriesForPath:imagesPath];
		}

		if (inPath) {
			//Just get it from the original path. This is especially good for emoticons.
			success = YES;

		} else {
			/* If we get here, the image is not on disk. If we don't have a path at which to save images,
			 * save to the temporary directory.
			 */
			if (!imagesPath) {
				imagesPath = NSTemporaryDirectory();
			}

			//Make sure the image has an appropriate extension
			if ([[inName pathExtension] caseInsensitiveCompare:@"png"] != NSOrderedSame) {
				inName = [inName stringByAppendingPathExtension:@"png"];
			}	

			shortFileName = [inName safeFilenameString];
			inPath = [[NSFileManager defaultManager] uniquePathForPath:[imagesPath stringByAppendingPathComponent:shortFileName]];
			NSData *pngRep = [attachmentImage PNGRepresentation];
			if([pngRep length] == 0) AILog(@"Couldn't get png representation for image %@", attachmentImage);
			success = [pngRep writeToFile:inPath atomically:YES];
		}
		
		if (!success) {
			NSLog(@"Failed to write image %@",inName);
		}

	} else {
		success = YES;
	}
	
	if (success) {
		NSString *srcPath = [[[NSURL fileURLWithPath:inPath] absoluteString] stringByEscapingForXMLWithEntities:nil];
		NSString *altName = (inName ? [inName stringByEscapingForXMLWithEntities:nil] : [srcPath lastPathComponent]);

		if (attachmentImage) {
			//Include size information if possible
			NSSize imageSize = [attachmentImage size];
			AILog(@"AIHTMLDecoder: appending <img class=\"%@\" src=\"%@\" alt=\"%@\" width=\"%i\" height=\"%i\">", imageClass, srcPath, altName, (int)imageSize.width, (int)imageSize.height);
			[string appendFormat:@"<img class=\"%@\" src=\"%@\" alt=\"%@\" width=\"%i\" height=\"%i\">", imageClass, srcPath, altName, (int)imageSize.width, (int)imageSize.height];

		} else {
			AILog(@"AIHTMLDecoder: appending <img class=\"%@\" src=\"%@\" alt=\"%@\">", imageClass, srcPath, altName);
			[string appendFormat:@"<img class=\"%@\" src=\"%@\" alt=\"%@\">", imageClass, srcPath, altName];
		}
	}

	return success;
}

#pragma mark Accessors

- (NSString *) XMLNamespace
{
	return XMLNamespace;
}
- (void) setXMLNamespace:(NSString *)newXMLNamespace
{
	if(XMLNamespace != newXMLNamespace) {
		[XMLNamespace release];
		XMLNamespace = [newXMLNamespace copy];
	}
}

- (BOOL)generatesStrictXHTML
{
	return thingsToInclude.generateStrictXHTML;
}
- (void)setGeneratesStrictXHTML:(BOOL)newValue
{
	thingsToInclude.generateStrictXHTML = newValue;
}

- (BOOL)includesHeaders
{
	return thingsToInclude.headers;
}
- (void)setIncludesHeaders:(BOOL)newValue
{
	thingsToInclude.headers = newValue;
}

- (BOOL)includesFontTags
{
	return thingsToInclude.fontTags;
}
- (void)setIncludesFontTags:(BOOL)newValue
{
	thingsToInclude.fontTags = newValue;
}

- (BOOL)closesFontTags
{
	return thingsToInclude.closingFontTags;
}
- (void)setClosesFontTags:(BOOL)newValue
{
	thingsToInclude.closingFontTags = newValue;
}

- (BOOL)includesColorTags
{
	return thingsToInclude.colorTags;
}
- (void)setIncludesColorTags:(BOOL)newValue
{
	thingsToInclude.colorTags = newValue;
}

- (BOOL)includesStyleTags
{
	return thingsToInclude.styleTags;
}
- (void)setIncludesStyleTags:(BOOL)newValue
{
	thingsToInclude.styleTags = newValue;
}

- (BOOL)encodesNonASCII
{
	return thingsToInclude.nonASCII;
}
- (void)setEncodesNonASCII:(BOOL)newValue
{
	thingsToInclude.nonASCII = newValue;
}

- (BOOL)preservesAllSpaces
{
	return thingsToInclude.allSpaces;
}
- (void)setPreservesAllSpaces:(BOOL)newValue
{
	thingsToInclude.allSpaces = newValue;
}

- (BOOL)usesAttachmentTextEquivalents
{
	return thingsToInclude.attachmentTextEquivalents;
}
- (void)setUsesAttachmentTextEquivalents:(BOOL)newValue
{
	thingsToInclude.attachmentTextEquivalents = newValue;
}

- (BOOL)onlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage
{
	return thingsToInclude.onlyIncludeOutgoingImages;
}
- (void)setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:(BOOL)newValue
{
	thingsToInclude.onlyIncludeOutgoingImages = newValue;
}

- (BOOL)onlyUsesSimpleTags
{
	return thingsToInclude.simpleTagsOnly;
}
- (void)setOnlyUsesSimpleTags:(BOOL)newValue
{
	thingsToInclude.simpleTagsOnly = newValue;
}

- (BOOL)includesBodyBackground
{
	return thingsToInclude.bodyBackground;
}
- (void)setIncludesBodyBackground:(BOOL)newValue
{
	thingsToInclude.bodyBackground = newValue;
}

- (BOOL)allowAIMsubprofileLinks
{
	return thingsToInclude.allowAIMsubprofileLinks;
}
- (void)setAllowAIMsubprofileLinks:(BOOL)newValue
{
	thingsToInclude.allowAIMsubprofileLinks = newValue;
}

@end

static AIHTMLDecoder *classMethodInstance = nil;

@implementation AIHTMLDecoder (ClassMethodCompatibility)

+ (AIHTMLDecoder *)classMethodInstance
{
	if (classMethodInstance == nil)
		classMethodInstance = [[self alloc] init];
	return classMethodInstance;
}

//For compatibility
+ (NSString *)encodeHTML:(NSAttributedString *)inMessage encodeFullString:(BOOL)encodeFullString
{
	[self classMethodInstance];
	classMethodInstance->thingsToInclude.headers = 
	classMethodInstance->thingsToInclude.fontTags = 
	classMethodInstance->thingsToInclude.closingFontTags = 
	classMethodInstance->thingsToInclude.colorTags = 
	classMethodInstance->thingsToInclude.nonASCII = 
	classMethodInstance->thingsToInclude.allSpaces = 
		encodeFullString;
	classMethodInstance->thingsToInclude.styleTags = 
	classMethodInstance->thingsToInclude.attachmentTextEquivalents = 
		YES;
	classMethodInstance->thingsToInclude.onlyIncludeOutgoingImages = 
	classMethodInstance->thingsToInclude.simpleTagsOnly = 
	classMethodInstance->thingsToInclude.bodyBackground =
	classMethodInstance->thingsToInclude.allowAIMsubprofileLinks =
		NO;
	
	return [classMethodInstance encodeHTML:inMessage imagesPath:nil];
}

// inMessage: AttributedString to encode
// headers: YES to include HTML and BODY tags
// fontTags: YES to include FONT tags
// closeFontTags: YES to close the font tags
// styleTags: YES to include B/I/U tags
// closeStyleTagsOnFontChange: YES to close and re-insert style tags when opening a new font tag
// encodeNonASCII: YES to encode non-ASCII characters as their HTML equivalents
// encodeSpaces: YES to preserve spacing when displaying the HTML in a web browser by converting multiple spaces and tabs to &nbsp codes.
// attachmentsAsText: YES to convert all attachments to their text equivalent if possible; NO to imbed <IMG SRC="...> tags
// onlyIncludeOutgoingImages: YES to only convert attachments to <IMG SRC="...> tags which should be sent to another user. Only relevant if attachmentsAsText is NO.
// simpleTagsOnly: YES to separate out FONT tags and include only the most basic HTML elements. Intended for protocols with minimal formatting support such as MSN
// bodyBackground: YES to set an Adium-internal attribute, AIBodyColorAttributeName, if there's a background. Used only for the message view.
+ (NSString *)encodeHTML:(NSAttributedString *)inMessage
				 headers:(BOOL)includeHeaders 
				fontTags:(BOOL)includeFontTags
	  includingColorTags:(BOOL)includeColorTags 
		   closeFontTags:(BOOL)closeFontTags
			   styleTags:(BOOL)includeStyleTags
 closeStyleTagsOnFontChange:(BOOL)closeStyleTagsOnFontChange 
		  encodeNonASCII:(BOOL)encodeNonASCII
			encodeSpaces:(BOOL)encodeSpaces
			  imagesPath:(NSString *)imagesPath
	   attachmentsAsText:(BOOL)attachmentsAsText
onlyIncludeOutgoingImages:(BOOL)onlyIncludeOutgoingImages
		  simpleTagsOnly:(BOOL)simpleOnly
		  bodyBackground:(BOOL)bodyBackground
{
#pragma unused(closeStyleTagsOnFontChange)
	[self classMethodInstance];
	classMethodInstance->thingsToInclude.headers = includeHeaders;
	classMethodInstance->thingsToInclude.fontTags = includeFontTags;
	classMethodInstance->thingsToInclude.closingFontTags = closeFontTags;
	classMethodInstance->thingsToInclude.colorTags = includeColorTags;
	classMethodInstance->thingsToInclude.styleTags = includeStyleTags;
	classMethodInstance->thingsToInclude.nonASCII = encodeNonASCII;
	classMethodInstance->thingsToInclude.allSpaces = encodeSpaces;
	classMethodInstance->thingsToInclude.attachmentTextEquivalents = attachmentsAsText;
	classMethodInstance->thingsToInclude.onlyIncludeOutgoingImages = onlyIncludeOutgoingImages;
	classMethodInstance->thingsToInclude.simpleTagsOnly = simpleOnly;
	classMethodInstance->thingsToInclude.bodyBackground = bodyBackground;
	classMethodInstance->thingsToInclude.allowAIMsubprofileLinks = NO;

	return [classMethodInstance encodeHTML:inMessage imagesPath:imagesPath];
}

+ (NSAttributedString *)decodeHTML:(NSString *)inMessage
{
	return [[self classMethodInstance] decodeHTML:inMessage withDefaultAttributes:nil];
}

+ (NSAttributedString *)decodeHTML:(NSString *)inMessage withDefaultAttributes:(NSDictionary *)inDefaultAttributes
{
	return [[self classMethodInstance] decodeHTML:inMessage withDefaultAttributes:inDefaultAttributes];
}

+ (NSDictionary *)parseArguments:(NSString *)arguments
{
	return [[self classMethodInstance] parseArguments:arguments];
}

@end

#pragma mark C functions

int HTMLEquivalentForFontSize(int fontSize)
{
	if (fontSize <= 9) {
		return 1;
	} else if (fontSize <= 10) {
		return 2;
	} else if (fontSize <= 12) {
		return 3;
	} else if (fontSize <= 14) {
		return 4;
	} else if (fontSize <= 18) {
		return 5;
	} else if (fontSize <= 24) {
		return 6;
	} else {
		return 7;
	}
}

@implementation NSString (AIHTMLDecoderAdditions)

/*!
 * @brief Allow absoluteString to be called on NSString objects
 *
 * This exists to work around an incompatibilty with older, buggy versions of Adium which would incorrectly set
 * an NSString for the NSLinkAttributeName attribute of an NSAttributedString.  This should always be an NUSRL.
 * Rather than figure out upgrade code in every possible lcoation, we just allow NSString to have absoluteString called
 * upon it, which is how we get the string value of NSURL objects.
 */
- (NSString *)absoluteString
{
	return self;
}

/*!
 * @brief Convert ASCII Symbol font to the appropriate Unicode characters
 *
 * This is needed because Windows Symbol font uses the normal ASCII range while OS X's uses Unicode properly.
 * A table extracted from http://www.alanwood.net/demos/symbol.html converts
 * Symbol characters in the 32 to 254 range into their Unicode equivalents (also in the Symbol font).
 *
 * Characters which can't be converted are replaced by ''.
 */
- (NSString *)stringByConvertingSymbolToSymbolUnicode
{
	NSMutableString		*decodedString = [NSMutableString string];

	//Symbol to Unicode Escape for characters 32 through 126 in the Symbol font
	static const char *lowSymbolTable[] = {
		" ", "", "\xE2\x88\x80", "", "\xE2\x88\x83", "", "", "\xE2\x88\x8D", "", "", "\xE2\x88\x97",
		"", "", "\xE2\x88\x92", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
		"\xE2\x89\x85", "\xCE\x91", "\xCE\x92", "\xCE\xA7", "\xCE\x94", "\xCE\x95", "\xCE\xA6", "\xCE\x93",
		"\xCE\x97", "\xCE\x99", "\xCF\x91", "\xCE\x9A", "\xCE\x9B", "\xCE\x9C", "\xCE\x9D", "\xCE\x9F",
		"\xCE\xA0", "\xCE\x98", "\xCE\xA1", "\xCE\xA3", "\xCE\xA4", "\xCE\xA5", "\xCF\x82", "\xCE\xA9",
		"\xCE\x9E", "\xCE\xA8", "\xCE\x96", "", "\xE2\x88\xB4", "", "\xE2\x8A\xA5", "", "", "\xCE\xB1",
		"\xCE\xB2", "\xCF\x87", "\xCE\xB4", "\xCE\xB5", "\xCF\x86", "\xCE\xB3", "\xCE\xB7", "\xCE\xB9", "\xCF\x95",
		"\xCE\xBA", "\xCE\xBB", "\xCE\xBC", "\xCE\xBD", "\xCE\xBF", "\xCF\x80", "\xCE\xB8", "\xCF\x81", "\xCF\x83",
		"\xCF\x84", "\xCF\x85", "\xCF\x96", "\xCF\x89", "\xCE\xBE", "\xCF\x88", "\xCE\xB6", "", "", "", "\xE2\x88\xBC"	};

	//Symbol to Unicode Escape for characters 161 through 254 in the Symbol font
	static const char *highSymbolTable[] = {
		"\xCF\x92", "\xE2\x80\xB2", "\xE2\x89\xA4", "\xE2\x81\x84", "\xE2\x88\x9E", "\xC6\x92", "\xE2\x99\xA3",
		"\xE2\x99\xA6", "\xE2\x99\xA5", "\xE2\x99\xA0", "\xE2\x86\x94", "\xE2\x86\x90", "\xE2\x86\x91", "\xE2\x86\x92",
		"\xE2\x86\x93", "\xC2\xB1", "\xE2\x80\xB3", "\xE2\x89\xA5", "\xC3\x97", "\xE2\x88\x9D", "\xE2\x88\x82", "\xE2\x88\x99",
		"\xC3\xB7", "\xE2\x89\xA0", "\xE2\x89\xA1", "\xE2\x89\x88", "\xE2\x80\xA6", "\xE2\x8F\x90", "\xE2\x8E\xAF",
		"\xE2\x86\xB5", "\xE2\x84\xB5", "\xE2\x84\x91", "\xE2\x84\x9C", "\xE2\x84\x98", "\xE2\x8A\x97", "\xE2\x8A\x95",
		"\xE2\x88\x85", "\xE2\x88\xA9", "\xE2\x88\xAA", "\xE2\x8A\x83", "\xE2\x8A\x87", "\xE2\x8A\x84", "\xE2\x8A\x82",
		"\xE2\x8A\x86", "\xE2\x88\x88", "\xE2\x88\x89", "\xE2\x88\xA0", "\xE2\x88\x87", "\xC2\xAE", "\xC2\xA9", "\xE2\x84\xA2",
		"\xE2\x88\x8F", "\xE2\x88\x9A", "\xE2\x8B\x85", "\xC2\xAC", "\xE2\x88\xA7", "\xE2\x88\xA8", "\xE2\x87\x94",
		"\xE2\x87\x90", "\xE2\x87\x91", "\xE2\x87\x92", "\xE2\x87\x93", "\xE2\x97\x8A", "\xE2\x8C\xA9", "\xC2\xAE",
		"\xC2\xA9", "\xE2\x84\xA2", "\xE2\x88\x91", "\xE2\x8E\x9B", "\xE2\x8E\x9C", "\xE2\x8E\x9D", "\xE2\x8E\xA1", "\xE2\x8E\xA2",
		"\xE2\x8E\xA3", "\xE2\x8E\xA7", "\xE2\x8E\xA8", "\xE2\x8E\xA9", "\xE2\x8E\xAA", "\xE2\x82\xAC", "\xE2\x8C\xAA",
		"\xE2\x88\xAB", "\xE2\x8C\xA0", "\xE2\x8E\xAE", "\xE2\x8C\xA1", "\xE2\x8E\x9E", "\xE2\x8E\x9F", "\xE2\x8E\xA0",
		"\xE2\x8E\xA4", "\xE2\x8E\xA5", "\xE2\x8E\xA6", "\xE2\x8E\xAB", "\xE2\x8E\xAC", "\xE2\x8E\xAD"};
	
	NSData *utf8Data = [self dataUsingEncoding:NSUTF8StringEncoding];
	const char *utf8String = [utf8Data bytes];
	unsigned sourceLength = [utf8Data length];
	
	for (int i = 0; i < sourceLength; i++) {
		unichar	ch = utf8String[i];
		const char *replacement;
		
		if (ch >= 32 && ch <= 126) {
			replacement = lowSymbolTable[ch - 32];

		} else if (ch >= 161 && ch <= 254) {
			replacement = highSymbolTable[ch - 161];

		} else {
			replacement = NULL;
		}

		if (replacement && strlen(replacement)) {
			[decodedString appendString:[NSString stringWithUTF8String:replacement]];

		} else {
			[decodedString appendFormat:@"%c", ch];			
		}
	}
	
	return decodedString;	
}

/*!
 * @brief Convert Wingdings characters to their Unicode equivalents if possible
 *
 * This table extracted from http://www.alanwood.net/demos/wingdings.html attempts to convert
 * Wingdings characters into Unicode equivalents.  Characters which can't be converted are replaced by ''.
 */
- (NSString *)stringByConvertingWingdingsToUnicode
{	
	NSMutableString		*decodedString = [NSMutableString string];

	//Wingdings to Unicode Escape for characters 32 through 255 in the Wingdings font
	static const char *wingdingsTable[] = {
		" ", "\xE2\x9C\x8F", "\xE2\x9C\x82", "\xE2\x9C\x81", "", "", "", "",
		"\xE2\x98\x8E", "\xE2\x9C\x86", "\xE2\x9C\x89", "", "", "", "",
		"", "", "", "", "", "", "", "\xE2\x8C\x9B", "\xE2\x8C\xA8", "",
		"", "", "", "", "", "\xE2\x9C\x87", "\xE2\x9C\x8D", "", "\xE2\x9C\x8C",
		"", "", "", "\xE2\x98\x9C", "\xE2\x98\x9E", "\xE2\x98\x9D", "\xE2\x98\x9F",
		"", "\xE2\x98\xBA", "", "\xE2\x98\xB9", "", "\xE2\x98\xA0", "\xE2\x9A\x90",
		"", "\xE2\x9C\x88", "\xE2\x98\xBC", "", "\xE2\x9D\x84", "", "\xE2\x9C\x9E",
		"", "\xE2\x9C\xA0", "\xE2\x9C\xA1", "\xE2\x98\xAA", "\xE2\x98\xAF", "\xE0\xA5\x90",
		"\xE2\x98\xB8", "\xE2\x99\x88", "\xE2\x99\x89", "\xE2\x99\x8A", "\xE2\x99\x8B",
		"\xE2\x99\x8C", "\xE2\x99\x8D", "\xE2\x99\x8E", "\xE2\x99\x8F", "\xE2\x99\x90",
		"\xE2\x99\x91", "\xE2\x99\x92", "\xE2\x99\x93", "&", "&", "\xE2\x97\x8F", "\xE2\x9D\x8D",
		"\xE2\x96\xA0", "\xE2\x96\xA1", "", "\xE2\x9D\x91", "\xE2\x9D\x92", "", "\xE2\x99\xA6",
		"\xE2\x97\x86", "\xE2\x9D\x96", "", "\xE2\x8C\xA7", "\xE2\x8D\x93", "\xE2\x8C\x98", "\xE2\x9D\x80",
		"\xE2\x9C\xBF", "\xE2\x9D\x9D", "\xE2\x9D\x9E", "\xE2\x96\xAF", "\xE2\x93\xAA", "\xE2\x91\xA0",
		"\xE2\x91\xA1", "\xE2\x91\xA2", "\xE2\x91\xA3", "\xE2\x91\xA4", "\xE2\x91\xA5", "\xE2\x91\xA6",
		"\xE2\x91\xA7", "\xE2\x91\xA8", "\xE2\x91\xA9", "\xE2\x93\xBF", "\xE2\x9D\xB6", "\xE2\x9D\xB7",
		"\xE2\x9D\xB8", "\xE2\x9D\xB9", "\xE2\x9D\xBA", "\xE2\x9D\xBB", "\xE2\x9D\xBC", "\xE2\x9D\xBD",
		"\xE2\x9D\xBE", "\xE2\x9D\xBF", "", "", "", "", "", "", "", "", "\xC2\xB7", "\xE2\x80\xA2",
		"\xE2\x96\xAA", "\xE2\x97\x8B", "", "", "\xE2\x97\x89", "\xE2\x97\x8E", "", "\xE2\x96\xAA",
		"\xE2\x97\xBB", "", "\xE2\x9C\xA6", "\xE2\x98\x85", "\xE2\x9C\xB6", "\xE2\x9C\xB4", "\xE2\x9C\xB9",
		"\xE2\x9C\xB5", "", "\xE2\x8C\x96", "\xE2\x9C\xA7", "\xE2\x8C\x91", "", "\xE2\x9C\xAA", "\xE2\x9C\xB0",
		"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
		"", "", "", "", "\xE2\x8C\xAB", "\xE2\x8C\xA6", "", "\xE2\x9E\xA2", "", "", "", "\xE2\x9E\xB2", "", "",
		"", "", "", "", "", "", "", "", "", "\xE2\x9E\x94", "", "", "", "", "", "", "\xE2\x87\xA6", "\xE2\x87\xA8",
		"\xE2\x87\xA7", "\xE2\x87\xA9", "\xE2\xAC\x84", "\xE2\x87\xB3", "\xE2\xAC\x80", "\xE2\xAC\x81", "\xE2\xAC\x83",
		"\xE2\xAC\x82", "\xE2\x96\xAD", "\xE2\x96\xAB", "\xE2\x9C\x97", "\xE2\x9C\x93", "\xE2\x98\x92", "\xE2\x98\x91", ""};
	
	NSData *utf8Data = [self dataUsingEncoding:NSUTF8StringEncoding];
	const char *utf8String = [utf8Data bytes];
	unsigned sourceLength = [utf8Data length];
	
	for (int i = 0; i < sourceLength; i++) {
		unichar	ch = utf8String[i];
		if (ch >= 32 && ch <= 255) {
			[decodedString appendString:[NSString stringWithUTF8String:wingdingsTable[ch - 32]]];
		} else {
			[decodedString appendFormat:@"%c", ch];
		}
	}
	
	return decodedString;
}

@end
