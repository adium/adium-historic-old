/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIHTMLDecoder.h"
#import "AITextAttributes.h"
#import "AIAttributedStringAdditions.h"
#import "AIColorAdditions.h"

int HTMLEquivalentForFontSize(int fontSize);

@interface AIHTMLDecoder (PRIVATE)

- (void)processFontTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (void)processBodyTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (void)processLinkTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
- (NSAttributedString *)processImgTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;

- (BOOL)appendImage:(NSImage *)attachmentImage toString:(NSMutableString *)string withName:(NSString *)fileSafeChunk  altString:(NSString *)attachmentString imagesPath:(NSString *)imagesPath;
- (void)appendFileTransferReferenceFromPath:(NSString *)path toString:(NSMutableString *)string;

@end

@implementation AIHTMLDecoder

static AITextAttributes *_defaultTextDecodingAttributes = nil;

DeclareString(HTML);
DeclareString(CloseHTML);
DeclareString(Body);
DeclareString(CloseBody);
DeclareString(Font);
DeclareString(CloseFont);
DeclareString(Span);
DeclareString(CloseSpan);
DeclareString(BR);
DeclareString(BRSlash);
DeclareString(CloseBR);
DeclareString(B);
DeclareString(CloseB);
DeclareString(I);
DeclareString(CloseI);
DeclareString(U);
DeclareString(CloseU);
DeclareString(P);
DeclareString(CloseP);
DeclareString(IMG);
DeclareString(CloseIMG);
DeclareString(Face);
DeclareString(SIZE);
DeclareString(Color);
DeclareString(Back);
DeclareString(ABSZ);
DeclareString(OpenFontTag);
DeclareString(CloseFontTag);
DeclareString(SizeTag);
DeclareString(BRTag);
DeclareString(Return);
DeclareString(Newline);
DeclareString(Ampersand);
DeclareString(AmpersandHTML);
DeclareString(LessThan);
DeclareString(LessThanHTML);
DeclareString(GreaterThan);
DeclareString(GreaterThanHTML);
DeclareString(Semicolon);
DeclareString(SpaceGreaterThan);
DeclareString(TagCharStartString);
DeclareString(Tab);
DeclareString(TabHTML);
DeclareString(LeadSpace);
DeclareString(LeadSpaceHTML);
DeclareString(Space);
DeclareString(SpaceHTML);

+ (void)initialize
{
	InitString(HTML,@"HTML");
	InitString(CloseHTML,@"/HTML");
	InitString(Body,@"BODY");
	InitString(CloseBody,@"/BODY");
	InitString(Font,@"FONT");
	InitString(CloseFont,@"/FONT");
	
	InitString(Span,@"SPAN");
	InitString(CloseSpan,@"/SPAN");
	InitString(BR,@"BR");
	InitString(BRSlash,@"BR/");
	InitString(CloseBR,@"/BR");
	InitString(B,@"B");
	InitString(CloseB,@"/B");
	InitString(I,@"I");
	InitString(CloseI,@"/I");
	InitString(U,@"U");
	InitString(CloseU,@"/U");
	InitString(P,@"P");
	InitString(CloseP,@"/P");
	
	InitString(IMG,@"IMG");
	InitString(CloseIMG,@"/IMG");
	InitString(Face,@"FACE");
	InitString(SIZE,@"SIZE");
	InitString(Color,@"COLOR");
	InitString(Back,@"BACK");
	InitString(ABSZ,@"ABSZ");
	
	InitString(OpenFontTag,@"<FONT");
	InitString(CloseFontTag,@"</FONT>");
	InitString(SizeTag,@" ABSZ=\"%i\" SIZE=\"%i\"");
	InitString(BRTag,@"<BR>");
	InitString(Return,@"\r");
	InitString(Newline,@"\n");
	
	InitString(Ampersand,@"&");
	InitString(AmpersandHTML,@"&amp;");
	
	InitString(LessThan,@"<");
	InitString(LessThanHTML,@"&lt;");
	
	InitString(GreaterThan,@">");
	InitString(GreaterThanHTML,@"&gt;");
	
	InitString(Semicolon,@";");
	InitString(SpaceGreaterThan,@" >");
	InitString(TagCharStartString,@"<&");

	InitString(Tab,@"\t");
	InitString(TabHTML,@" &nbsp;&nbsp;&nbsp;");
	
	InitString(LeadSpace,@" ");
	InitString(LeadSpaceHTML,@"&nbsp;");
	
	InitString(Space,@"  ");
	InitString(SpaceHTML,@" &nbsp;");
	
	if (!_defaultTextDecodingAttributes){
		_defaultTextDecodingAttributes = [[AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12] retain];
	}
}

+ (AIHTMLDecoder *)decoder
{
	return [[self new] autorelease];
}

- (id)initWithHeaders:(BOOL)includeHeaders
			 fontTags:(BOOL)includeFontTags
		closeFontTags:(BOOL)closeFontTags
			colorTags:(BOOL)includeColorTags
			styleTags:(BOOL)includeStyleTags
	   encodeNonASCII:(BOOL)encodeNonASCII
		 encodeSpaces:(BOOL)encodeSpaces
	attachmentsAsText:(BOOL)attachmentsAsText
attachmentImagesOnlyForSending:(BOOL)attachmentImagesOnlyForSending
	   simpleTagsOnly:(BOOL)simpleOnly
	   bodyBackground:(BOOL)bodyBackground
{
	self = [self init];
	thingsToInclude.headers                        = includeHeaders;
	thingsToInclude.fontTags                       = includeFontTags;
	thingsToInclude.closingFontTags                = closeFontTags;
	thingsToInclude.colorTags                      = includeColorTags;
	thingsToInclude.styleTags                      = includeStyleTags;
	thingsToInclude.nonASCII                       = encodeNonASCII;
	thingsToInclude.allSpaces                      = encodeSpaces;
	thingsToInclude.attachmentTextEquivalents      = attachmentsAsText;
	thingsToInclude.attachmentImagesOnlyForSending = attachmentImagesOnlyForSending;
	thingsToInclude.simpleTagsOnly                 = simpleOnly;
	thingsToInclude.bodyBackground                 = bodyBackground;
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
	   attachmentImagesOnlyForSending:(BOOL)attachmentImagesOnlyForSending
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
		   attachmentImagesOnlyForSending:attachmentImagesOnlyForSending
						   simpleTagsOnly:simpleOnly
						   bodyBackground:bodyBackground] autorelease];
}

#pragma mark Work methods

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
	if(!equalsSet) equalsSet = [[NSCharacterSet characterSetWithCharactersInString:@"="]  retain];
	if(!dquoteSet) dquoteSet = [[NSCharacterSet characterSetWithCharactersInString:@"\""] retain];
	if(!squoteSet) squoteSet = [[NSCharacterSet characterSetWithCharactersInString:@"'"]  retain];
	if(!spaceSet)  spaceSet  = [[NSCharacterSet characterSetWithCharactersInString:@" "]  retain];

	scanner = [NSScanner scannerWithString:arguments];
	argDict = [NSMutableDictionary dictionary];

	while(![scanner isAtEnd]){
		BOOL	validKey, validValue;

		//Find a tag
		validKey = [scanner scanUpToCharactersFromSet:equalsSet intoString:&key];
		[scanner scanCharactersFromSet:equalsSet intoString:nil];

		//check for quotes
		if([scanner scanCharactersFromSet:dquoteSet intoString:nil]){
			validValue = [scanner scanUpToCharactersFromSet:dquoteSet intoString:&value];
			[scanner scanCharactersFromSet:dquoteSet intoString:nil];
		} else if([scanner scanCharactersFromSet:squoteSet intoString:nil]) {
			validValue = [scanner scanUpToCharactersFromSet:squoteSet intoString:&value];
			[scanner scanCharactersFromSet:squoteSet intoString:nil];
		} else {
			validValue = [scanner scanUpToCharactersFromSet:spaceSet intoString:&value];
		}

		//Store in dict
		if(validValue && value != nil && [value length] != 0 && validKey && key != nil && [key length] != 0){ //Watch out for invalid & empty tags
			[argDict setObject:value forKey:key];
		}
	}

	return argDict;
}

- (NSString *)encodeHTML:(NSAttributedString *)inMessage imagesPath:(NSString *)imagesPath
{
	NSFontManager	*fontManager = [NSFontManager sharedFontManager];
	NSRange			searchRange;
	NSColor			*pageColor = nil;
	BOOL           openFontTag = NO;

	//Setup the destination HTML string
	NSMutableString *string = [NSMutableString string];
	if(thingsToInclude.headers) [string appendString:@"<HTML>"];

	//Setup the incoming message as a regular string, and get its length
	NSString		*inMessageString = [inMessage string];
	int				messageLength = [inMessageString length];
		
	//Setup the default attributes
	NSString		*currentFamily = [@"Helvetica" retain];
	NSString		*currentColor = nil;
	int				currentSize = 12;
	BOOL			currentItalic = NO;
	BOOL			currentBold = NO;
	BOOL			currentUnderline = NO;
	BOOL			currentStrikethrough = NO;
	NSString		*link = nil;
	NSString		*oldLink = nil;
	
	//Append the body tag (If there is a background color)
	if(thingsToInclude.headers && messageLength > 0 && (pageColor = [inMessage attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil])){
		[string appendString:@"<BODY BGCOLOR=\"#"];
		[string appendString:[pageColor hexString]];
		[string appendString:@"\">"];
	}
	
	//Loop through the entire string
	searchRange = NSMakeRange(0,0);
	while(searchRange.location < messageLength){
		NSDictionary	*attributes = [inMessage attributesAtIndex:searchRange.location effectiveRange:&searchRange];
		NSFont			*font = [attributes objectForKey:NSFontAttributeName];
		NSString		*color = [[attributes objectForKey:NSForegroundColorAttributeName] hexString];
		NSString		*familyName = [font familyName];
		float			pointSize = [font pointSize];

		NSFontTraitMask	traits = [fontManager traitsOfFont:font];
		BOOL			hasUnderline = [[attributes objectForKey:NSUnderlineStyleAttributeName] intValue];
		BOOL			hasStrikethrough = ([NSApp isOnPantherOrBetter] ? 
											[[attributes objectForKey:NSStrikethroughStyleAttributeName] intValue] :
											NO);
		BOOL			isBold = (traits & NSBoldFontMask);
		BOOL			isItalic = (traits & NSItalicFontMask);
		
		link = [attributes objectForKey:NSLinkAttributeName];
		
		//If we had a link on the last pass, and we don't now or we have a different one, close the link tag
		if (oldLink &&
			(!link || (([link length] != 0) && ![oldLink isEqualToString:link]))){

			//Close Link
			[string appendString:@"</a>"];
			oldLink = nil;
		}
		
		NSMutableString	*chunk = [[inMessageString substringWithRange:searchRange] mutableCopy];

		//Font (If the color, font, or size has changed)
		if(thingsToInclude.fontTags && (pointSize != currentSize ||
							   ![familyName isEqualToString:currentFamily] ||
							   (color && ![color isEqualToString:currentColor]) ||
							   (!color && currentColor))){

			//Close any existing font tags, and open a new one
			if(thingsToInclude.closingFontTags && openFontTag){
				[string appendString:CloseFontTag];
			}
			if (!thingsToInclude.simpleTagsOnly){
				openFontTag = YES;
				[string appendString:OpenFontTag];
			}

			//Family
			if(familyName && (![familyName isEqualToString:currentFamily] || thingsToInclude.closingFontTags)){
				if (thingsToInclude.simpleTagsOnly){
					[string appendString:[NSString stringWithFormat:@"<FONT FACE=\"%@\">",familyName]];
				}else{
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
			if((pointSize != currentSize) && !thingsToInclude.simpleTagsOnly){
				[string appendString:[NSString stringWithFormat:SizeTag, (int)pointSize, HTMLEquivalentForFontSize((int)pointSize)]];
				currentSize = pointSize;
			}

			//Color
			if(thingsToInclude.colorTags && (([color compare:currentColor] || (currentColor && !color)) || thingsToInclude.closingFontTags)){
				if (color){
					if(thingsToInclude.simpleTagsOnly){
						[string appendString:[NSString stringWithFormat:@"<FONT COLOR=\"#%@\">",color]];	
					}else{
						[string appendString:[NSString stringWithFormat:@" COLOR=\"#%@\"",color]];
					}
				}
				[currentColor release]; currentColor = [color retain];
			}

			//Close the font tag if necessary
			if (!thingsToInclude.simpleTagsOnly){
				[string appendString:GreaterThan];
			}
		}

		//Style (Bold, italic, underline, strikethrough)
		if(thingsToInclude.styleTags){			
			if(currentItalic && !isItalic){
				[string appendString:@"</I>"];
				currentItalic = NO;
			}else  if(!currentItalic && isItalic){
				[string appendString:@"<I>"];
				currentItalic = YES;
			}

			if (currentUnderline && !hasUnderline){
				[string appendString:@"</U>"];
				currentUnderline = NO;
			} else if(!currentUnderline && hasUnderline){
				[string appendString:@"<U>"];
				currentUnderline = YES;
			}

			if (currentBold && !isBold){
				[string appendString:@"</B>"];
				currentBold = NO;
			} else if(!currentBold && isBold){
				[string appendString:@"<B>"];
				currentBold = YES;
			}
        
        if (currentStrikethrough && !hasStrikethrough){
           [string appendString:@"</S>"];
           currentStrikethrough = NO;
        } else if(!currentStrikethrough && hasStrikethrough){
           [string appendString:@"<S>"];
           currentStrikethrough = YES;
        }
		}

		//Link
		if(!oldLink && link && [link length] != 0){
			NSString	*linkString = ([link isKindOfClass:[NSURL class]] ? [(NSURL *)link absoluteString] : link);

			[string appendString:@"<a href=\""];
			[string appendString:linkString];
			if (!thingsToInclude.simpleTagsOnly){
				[string appendString:@"\" title=\""];
				[string appendString:linkString];
			}
			[string appendString:@"\">"];
			
			oldLink = linkString;
		}

		//Image Attachments
		if([attributes objectForKey:NSAttachmentAttributeName]){
			int i;

			for(i = 0; (i < searchRange.length); i++){ //Each attachment takes a character.. they are grouped by the attribute scan
				NSTextAttachment *textAttachment = [[inMessage attributesAtIndex:searchRange.location+i effectiveRange:nil] objectForKey:NSAttachmentAttributeName];
				if (textAttachment){

					//We can work efficiently on an AITextAttachmentExtension
					if ([textAttachment isKindOfClass:[AITextAttachmentExtension class]]){

						//Suppress compiler stupidity
						AITextAttachmentExtension *attachment = (AITextAttachmentExtension *)textAttachment;

						if((imagesPath) &&
						   ([attachment shouldSaveImageForLogging]) && 
						   ([[attachment attachmentCell] respondsToSelector:@selector(image)])){

							//We have an NSImage but no file at which to point the img tag
							NSString			*attachmentString;

							attachmentString = [attachment string];

							if ([self appendImage:[[attachment attachmentCell] performSelector:@selector(image)]
										 toString:string
										 withName:[attachmentString safeFilenameString]
										altString:attachmentString
									   imagesPath:imagesPath]){

								//We were succesful appending the image tag, so release this chunk
								[chunk release]; chunk = nil;	
							}

						}else if(!thingsToInclude.attachmentTextEquivalents &&
								 (!thingsToInclude.attachmentImagesOnlyForSending || ![attachment shouldAlwaysSendAsText])){
							//We want attachments as images where appropriate, and this attachment is not marked
							//to always send as text.  The attachment will have an imagePath pointing to a file
							//which we can link directly via an img tag.

							NSSize imageSize = [attachment imageSize];

							[string appendFormat:@"<img src=\"file://%@\" alt=\"%@\" width=\"%i\" height=\"%i\">",
								[[attachment imagePath] stringByEscapingForHTML], [[attachment string] stringByEscapingForHTML],
								(int)imageSize.width, (int)imageSize.height];

							//Release the chunk
							[chunk release]; chunk = nil;

						}else{
							//We should replace the attachment with its textual equivalent if possible

							NSString	*attachmentString = [attachment string];
							if (attachmentString){
								[string appendString:attachmentString];
							}

							[chunk release]; chunk = nil;
						}
					}else{
						//Our attachment is just a standard NSTextAttachment, which means we now have to deal with
						//the fileWrapper.
						NSFileWrapper   *fileWrapper = [textAttachment fileWrapper];
						NSDictionary	*fileAttributes = [fileWrapper fileAttributes];
						OSType			HFSTypeCode;

						HFSTypeCode = [[fileAttributes objectForKey:NSFileHFSTypeCode] unsignedLongValue];

						//Check the HFSTypeCode (encoded to the NSString format [NSImage imageFileTypes] uses)
						//We also want to ensure that we have a path for writing out images; otherwise a normal
						//attachment-to-file-transfer tagging is in order.
						if (imagesPath &&
							[[NSImage imageFileTypes] containsObject:NSFileTypeForHFSTypeCode(HFSTypeCode)]){

							NSString	*imageName = [fileWrapper preferredFilename];

							//We've got an image, so the attachment's attachmentCell 
							//already has the NSImage we want to append
							if ([self appendImage:[[textAttachment attachmentCell] performSelector:@selector(image)]
										 toString:string
										 withName:imageName
										altString:imageName
									   imagesPath:imagesPath]){

								//We were succesful appending the image tag, so release this chunk
								[chunk release]; chunk = nil;	
							}
						}else{
							//Got a non-image file.  Use a special Adium tag so code elsewhere knows to handle what
							//was previously the attachment as a file transfer.
							if ([fileWrapper isKindOfClass:[ESFileWrapperExtension class]]){
								if ([fileWrapper isDirectory]){
									// XXX got passed a directory.  Porbably want to process it recursively for now
								}else if ([fileWrapper isSymbolicLink]){
									// XXX got passed a symbolic link.  I guess maybe resolve it and use it like a regular file?
								}else{
									//Regular file.  It's go time.
									NSString	*path = [(ESFileWrapperExtension *)fileWrapper originalPath];

									if (path){
										[self appendFileTransferReferenceFromPath:path
																		 toString:string];

										//We were succesful appending the FT tag, so release this chunk
										[chunk release]; chunk = nil;	
									}
								}
							}
						}
					}
				}
			}
		}

		if(chunk){
			//Escape special HTML characters.
			[chunk replaceOccurrencesOfString:Ampersand withString:AmpersandHTML
									  options:NSLiteralSearch range:NSMakeRange(0, [chunk length])];
			[chunk replaceOccurrencesOfString:LessThan withString:LessThanHTML
									  options:NSLiteralSearch range:NSMakeRange(0, [chunk length])];
			[chunk replaceOccurrencesOfString:GreaterThan withString:GreaterThanHTML
									  options:NSLiteralSearch range:NSMakeRange(0, [chunk length])];

			if(thingsToInclude.allSpaces){
				// Replace the tabs first, if they exist, so that it creates a leading " " when the tab is the initial character, and 
				// so subsequent tab formatting is preserved.
				[chunk replaceOccurrencesOfString:Tab withString:TabHTML
										  options:NSLiteralSearch
											range:NSMakeRange(0, [chunk length])];
				// Check to make sure chunk exists before checking the characterAtIndex and then replace the leading ' ' with "&nbsp;" to preserve formatting.
				if([chunk length] > 0 && [chunk characterAtIndex:0] == ' '){
					[chunk replaceOccurrencesOfString:LeadSpace withString:LeadSpaceHTML
											  options:NSLiteralSearch
												range:NSMakeRange(0, 1)];
				}
				// Replace all remaining blocks of "  " (<space><space>) with " &nbsp;" (<space><&nbsp;>) so that formatting of large blocks of spaces
				// in the middle of a line is preserved, and so WebKit properly line-wraps.
				[chunk replaceOccurrencesOfString:Space withString:SpaceHTML
										  options:NSLiteralSearch
											range:NSMakeRange(0, [chunk length])];
			}

			//If we need to encode non-ASCII to HTML, append string character by
			//  character, replacing any non-ascii characters with the
			//  designated SGML escape sequence.
			if (thingsToInclude.nonASCII) {
				unsigned i;
				unsigned length = [chunk length];
				for(i = 0; i < length; i++){
					unichar currentChar = [chunk characterAtIndex:i];
					if(currentChar > 127){
						[string appendFormat:@"&#%d;", currentChar];
					}else if(currentChar == '\r' || currentChar == '\n'){
						[string appendString:BRTag];
					}else{
						//unichar characters may have a length of up to 3; be careful to get the whole character
						NSRange composedCharRange = [chunk rangeOfComposedCharacterSequenceAtIndex:i];
						[string appendString:[chunk substringWithRange:composedCharRange]];
						i += composedCharRange.length - 1;
					}
				}
			} else {
				[chunk replaceOccurrencesOfString:Return withString:BRTag options:NSLiteralSearch range:NSMakeRange(0, [chunk length])];
				[chunk replaceOccurrencesOfString:Newline withString:BRTag options:NSLiteralSearch range:NSMakeRange(0, [chunk length])];
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
	if(thingsToInclude.styleTags) {
		if(currentItalic) [string appendString:@"</I>"];
		if(currentBold) [string appendString:@"</B>"];
		if(currentUnderline) [string appendString:@"</U>"];
      if(currentStrikethrough) [string appendString:@"</S>"];
	}
	
	//If we had a link on the last pass, close the link tag
	if (oldLink){
		//Close Link
		[string appendString:@"</a>"];
		oldLink = nil;
	}
	
	if(thingsToInclude.fontTags && thingsToInclude.closingFontTags && openFontTag) [string appendString:CloseFontTag]; //Close any open font tag
	if(thingsToInclude.headers && pageColor) [string appendString:@"</BODY>"]; //Close the body tag
	if(thingsToInclude.headers) [string appendString:@"</HTML>"]; //Close the HTML
	
	//KBOTC's odd hackish body background thingy for WMV since no one else will add it
	if(thingsToInclude.bodyBackground){
		[string setString:@""];
		if(pageColor = [inMessage attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil]){
		[string setString:[pageColor hexString]];
		[string replaceOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
		}
	}
/*	NSLog(@"encoded %@", inMessage);
	NSLog(@"to HTML %@", string);
*/
	return string;
}

- (NSAttributedString *)decodeHTML:(NSString *)inMessage
{
	NSScanner					*scanner;
	static NSCharacterSet		*tagCharStart = nil, *tagEnd = nil, *charEnd = nil, *absoluteTagEnd = nil;
	NSString					*chunkString, *tagOpen;
	NSMutableAttributedString	*attrString;
	AITextAttributes			*textAttributes;
	BOOL						send = NO, receive = NO, inDiv = NO, inLogSpan = NO;

    //set up
    textAttributes = [[_defaultTextDecodingAttributes copy] autorelease];
    attrString = [[NSMutableAttributedString alloc] init];

	if(!tagCharStart)     tagCharStart = [[NSCharacterSet characterSetWithCharactersInString:TagCharStartString] retain];
	if(!tagEnd)                 tagEnd = [[NSCharacterSet characterSetWithCharactersInString:SpaceGreaterThan] retain];
	if(!charEnd)               charEnd = [[NSCharacterSet characterSetWithCharactersInString:Semicolon]          retain];
	if(!absoluteTagEnd) absoluteTagEnd = [[NSCharacterSet characterSetWithCharactersInString:GreaterThan] retain];

	scanner = [NSScanner scannerWithString:inMessage];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

	//Parse the HTML
	while(![scanner isAtEnd]){
		//Find an HTML tag or escaped character
		if([scanner scanUpToCharactersFromSet:tagCharStart intoString:&chunkString]){
			[attrString appendString:chunkString withAttributes:[textAttributes dictionary]];
		}

		//Process the tag
		if([scanner scanCharactersFromSet:tagCharStart intoString:&tagOpen]){ //If a tag wasn't found, we don't process.
			unsigned scanLocation = [scanner scanLocation]; //Remember our location (if this is an invalid tag we'll need to move back)

			if([tagOpen isEqualToString:LessThan]){ // HTML <tag>
				BOOL validTag = [scanner scanUpToCharactersFromSet:tagEnd intoString:&chunkString]; //Get the tag
				if(validTag){ 
					//HTML
					if([chunkString caseInsensitiveCompare:HTML] == NSOrderedSame){
						//We ignore stuff inside the HTML tag, but don't want to see the end of it
						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];
					}else if([chunkString caseInsensitiveCompare:CloseHTML] == NSOrderedSame){
						//We are done
						break;

					//PRE -- ignore attributes for logViewer
					}else if([chunkString caseInsensitiveCompare:@"PRE"] == NSOrderedSame ||
							 [chunkString caseInsensitiveCompare:@"/PRE"] == NSOrderedSame){

						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];

						[textAttributes setTextColor:[NSColor blackColor]];
					//DIV
					}else if ([chunkString caseInsensitiveCompare:@"DIV"] == NSOrderedSame){
						[scanner scanUpToCharactersFromSet:absoluteTagEnd
												intoString:&chunkString];
						inDiv = YES;
						if ([chunkString caseInsensitiveCompare:@" class=\"send\""] == NSOrderedSame) {
							send = YES;
							receive = NO;
						} else if ([chunkString caseInsensitiveCompare:@" class=\"receive\""] == NSOrderedSame) {
							receive = YES;
							send = NO;
						} else if ([chunkString caseInsensitiveCompare:@" class=\"status\""] == NSOrderedSame) {
							[textAttributes setTextColor:[NSColor grayColor]];
						}
					}else if ([chunkString caseInsensitiveCompare:@"/DIV"] == NSOrderedSame) {
						inDiv = NO;
					//LINK
					}else if([chunkString caseInsensitiveCompare:@"A"] == NSOrderedSame){
						//[textAttributes setUnderline:YES];
						//[textAttributes setTextColor:[NSColor blueColor]];
						if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
							[self processLinkTagArgs:[self parseArguments:chunkString] attributes:textAttributes]; //Process the linktag's contents
						}

					}else if([chunkString caseInsensitiveCompare:@"/A"] == NSOrderedSame){
						[textAttributes setLinkURL:nil];

					//Body
					}else if([chunkString caseInsensitiveCompare:Body] == NSOrderedSame){
						if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
							[self processBodyTagArgs:[self parseArguments:chunkString] attributes:textAttributes]; //Process the font tag's contents
						}

					}else if([chunkString caseInsensitiveCompare:CloseBody] == NSOrderedSame){
						//ignore

					//Font
					}else if([chunkString caseInsensitiveCompare:Font] == NSOrderedSame){
						if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){

							//Process the font tag if it's in a log
							if([chunkString caseInsensitiveCompare:@" class=\"sender\""] == NSOrderedSame) {
								if(inDiv && send) {
									[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0]];
								} else if(inDiv && receive) {
									[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.5 alpha:1.0]];
								}
							}

							//Process the font tag's contents
							[self processFontTagArgs:[self parseArguments:chunkString] attributes:textAttributes];
						}

					}else if([chunkString caseInsensitiveCompare:CloseFont] == NSOrderedSame){
						[textAttributes setTextColor:[NSColor blackColor]];
						[textAttributes setFontFamily:@"Helvetica"];
						[textAttributes setFontSize:12];

					//span
					}else if([chunkString caseInsensitiveCompare:Span] == NSOrderedSame){
						if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){

							//Process the span tag if it's in a log
							if([chunkString caseInsensitiveCompare:@" class=\"sender\""] == NSOrderedSame) {
								if(inDiv && send) {
									[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0]];
									inLogSpan = YES;
								} else if(inDiv && receive) {
									[textAttributes setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.5 alpha:1.0]];
									inLogSpan = YES;
								}
							} else if([chunkString caseInsensitiveCompare:@" class=\"timestamp\""] == NSOrderedSame){
								[textAttributes setTextColor:[NSColor grayColor]];
								inLogSpan = YES;
							}
							
							//XXX Jabber can send a tag like so: <span style='font-family: Helvetica; font-size: small; '>
						}
					} else if ([chunkString caseInsensitiveCompare:CloseSpan] == NSOrderedSame) {
						if(inLogSpan){
							[textAttributes setTextColor:[NSColor blackColor]];
							[textAttributes setFontFamily:@"Helvetica"];
							[textAttributes setFontSize:12];
							inLogSpan = NO;
						}
					//Line Break
					}else if([chunkString caseInsensitiveCompare:BR] == NSOrderedSame || 
							 [chunkString caseInsensitiveCompare:BRSlash] == NSOrderedSame ||
							 [chunkString caseInsensitiveCompare:CloseBR] == NSOrderedSame){
						[attrString appendString:Return withAttributes:nil];
						//Make sure the tag closes, since it may have a <BR /> which stopped the scanner at the space, not the >
						[scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];

					//Bold
					}else if([chunkString caseInsensitiveCompare:B] == NSOrderedSame){
						[textAttributes enableTrait:NSBoldFontMask];
					}else if([chunkString caseInsensitiveCompare:CloseB] == NSOrderedSame){
						[textAttributes disableTrait:NSBoldFontMask];

					//Strong (interpreted as bold)
					}else if([chunkString caseInsensitiveCompare:@"STRONG"] == NSOrderedSame){
						[textAttributes enableTrait:NSBoldFontMask];
					}else if([chunkString caseInsensitiveCompare:@"/STRONG"] == NSOrderedSame){
						[textAttributes disableTrait:NSBoldFontMask];

					//Italic
					}else if([chunkString caseInsensitiveCompare:I] == NSOrderedSame){
						[textAttributes enableTrait:NSItalicFontMask];
					}else if([chunkString caseInsensitiveCompare:CloseI] == NSOrderedSame){
						[textAttributes disableTrait:NSItalicFontMask];

					//Emphasised (interpreted as italic)
					}else if([chunkString caseInsensitiveCompare:@"EM"] == NSOrderedSame){
						[textAttributes enableTrait:NSItalicFontMask];
					}else if([chunkString caseInsensitiveCompare:@"/EM"] == NSOrderedSame){
						[textAttributes disableTrait:NSItalicFontMask];

					//Underline
					}else if([chunkString caseInsensitiveCompare:U] == NSOrderedSame){
						[textAttributes setUnderline:YES];
					}else if([chunkString caseInsensitiveCompare:CloseU] == NSOrderedSame){
						[textAttributes setUnderline:NO];

					//Strikethrough: <s> is deprecated, but people use it
					} else if([chunkString caseInsensitiveCompare:@"S"] == NSOrderedSame) {
						[textAttributes setStrikethrough:YES];
					} else if([chunkString caseInsensitiveCompare:@"/S"] == NSOrderedSame) {
						[textAttributes setStrikethrough:NO];

					// Subscript
					} else if([chunkString caseInsensitiveCompare:@"SUB"] == NSOrderedSame)  {
						[textAttributes setSubscript:YES];
					} else if([chunkString caseInsensitiveCompare:@"/SUB"] == NSOrderedSame)  {
						[textAttributes setSubscript:NO];

					// Superscript
					} else if([chunkString caseInsensitiveCompare:@"SUP"] == NSOrderedSame)  {
						[textAttributes setSuperscript:YES];
					} else if([chunkString caseInsensitiveCompare:@"/SUP"] == NSOrderedSame)  {
						[textAttributes setSuperscript:NO];

					//Image
					} else if([chunkString caseInsensitiveCompare:IMG] == NSOrderedSame){
						if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
							NSAttributedString *attachString = [self processImgTagArgs:[self parseArguments:chunkString] attributes:textAttributes];
							[attrString appendAttributedString:attachString];
						}
					} else if([chunkString caseInsensitiveCompare:CloseIMG] == NSOrderedSame){
						//just ignore </img> if we find it

					// Ignore <p> for those wacky AIM express users
					} else if ([chunkString caseInsensitiveCompare:P] == NSOrderedSame ||
							   [chunkString caseInsensitiveCompare:CloseP] == NSOrderedSame) {

					//Invalid
					} else {
						validTag = NO;
					}
				}

				if(validTag){ //Skip over the end tag character '>'
					if (![scanner isAtEnd])
						[scanner setScanLocation:[scanner scanLocation]+1];
				}else{
					//When an invalid tag is encountered, we add the <, and then move our scanner back to continue processing
					[attrString appendString:LessThan withAttributes:[textAttributes dictionary]];
					[scanner setScanLocation:scanLocation];
				}

			}else if([tagOpen compare:Ampersand] == NSOrderedSame){ // escape character, eg &gt;
				BOOL validTag = [scanner scanUpToCharactersFromSet:charEnd intoString:&chunkString];

				if(validTag){
					// We could upgrade this to use an NSDictionary with lots of chars
					// but for now, if-blocks will do
					if ([chunkString caseInsensitiveCompare:@"GT"] == NSOrderedSame){
						[attrString appendString:GreaterThan withAttributes:[textAttributes dictionary]];

					}else if ([chunkString caseInsensitiveCompare:@"LT"] == NSOrderedSame){
						[attrString appendString:LessThan withAttributes:[textAttributes dictionary]];

					}else if ([chunkString caseInsensitiveCompare:@"AMP"] == NSOrderedSame){
						[attrString appendString:Ampersand withAttributes:[textAttributes dictionary]];

					}else if ([chunkString caseInsensitiveCompare:@"QUOT"] == NSOrderedSame){
						[attrString appendString:@"\"" withAttributes:[textAttributes dictionary]];

					}else if ([chunkString caseInsensitiveCompare:@"APOS"] == NSOrderedSame){
						[attrString appendString:@"'" withAttributes:[textAttributes dictionary]];

					}else if ([chunkString caseInsensitiveCompare:@"NBSP"] == NSOrderedSame){
						[attrString appendString:@" " withAttributes:[textAttributes dictionary]];

					}else if ([chunkString hasPrefix:@"#x"]) {
						[attrString appendString:[NSString stringWithFormat:@"%C",
							[chunkString substringFromIndex:1]]
							withAttributes:[textAttributes dictionary]];
					}else if ([chunkString hasPrefix:@"#"]) {
						[attrString appendString:[NSString stringWithFormat:@"%C", 
							[[chunkString substringFromIndex:1] intValue]] 
							withAttributes:[textAttributes dictionary]];
					}
					else{ //Invalid
						validTag = NO;
					}
				}

				if(validTag){ //Skip over the end tag character ';'.  Don't scan all of that character, however, as we'll skip ;; and so on.
					[scanner setScanLocation:[scanner scanLocation] + 1];
				}else{
					//When an invalid tag is encountered, we add the &, and then move our scanner back to continue processing
					[attrString appendString:Ampersand withAttributes:[textAttributes dictionary]];
					[scanner setScanLocation:scanLocation];
				}
			}else{ //Invalid tag character (most likely a stray < or &)
				if([tagOpen length] > 1){
					//If more than one character was scanned, add the first one, and move the scanner back to re-process the additional characters
					[attrString appendString:[tagOpen substringToIndex:1] withAttributes:[textAttributes dictionary]];
					[scanner setScanLocation:[scanner scanLocation] - ([tagOpen length]-1)]; 
				}else{
					[attrString appendString:tagOpen withAttributes:[textAttributes dictionary]];
				}
			}
		}
	}
	
	//If the string has a constant NSBackgroundColorAttributeName attribute and no AIBodyColorAttributeName,
	//we want to move the NSBackgroundColorAttributeName attribute to AIBodyColorAttributeName (Things are a
	//lot more attractive this way).
	if([attrString length]){
		NSRange backRange;
		NSColor *bodyColor = [attrString attribute:NSBackgroundColorAttributeName 
										   atIndex:0 
									effectiveRange:&backRange];
		if(bodyColor && (backRange.length == [attrString length])) {
			[attrString addAttribute:AIBodyColorAttributeName
							   value:bodyColor 
							   range:NSMakeRange(0,[attrString length])];
			[attrString removeAttribute:NSBackgroundColorAttributeName 
								  range:NSMakeRange(0,[attrString length])];
		}
	}
	
	return([attrString autorelease]);
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
	while((arg = [enumerator nextObject])){
		if([arg caseInsensitiveCompare:Face] == NSOrderedSame){
			[textAttributes setFontFamily:[inArgs objectForKey:arg]];

		}else if([arg caseInsensitiveCompare:SIZE] == NSOrderedSame){
			//Always prefer an ABSZ to a size
			if(![inArgs objectForKey:ABSZ] && ![inArgs objectForKey:@"absz"]){
				unsigned absSize = [[inArgs objectForKey:arg] intValue];
				static int pointSizes[] = { 9, 10, 12, 14, 18, 24, 48, 72 };
				int size = (absSize <= 8 ? pointSizes[absSize-1] : 12);

				[textAttributes setFontSize:size];
			}

		}else if([arg caseInsensitiveCompare:ABSZ] == NSOrderedSame){
			[textAttributes setFontSize:[[inArgs objectForKey:arg] intValue]];

		}else if([arg caseInsensitiveCompare:Color] == NSOrderedSame){
			[textAttributes setTextColor:[[inArgs objectForKey:arg] hexColor]];

		}else if([arg caseInsensitiveCompare:Back] == NSOrderedSame){
			[textAttributes setTextBackgroundColor:[[inArgs objectForKey:arg] hexColor]];

		}
	}
}

- (void)processBodyTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;

	enumerator = [[inArgs allKeys] objectEnumerator];
	while((arg = [enumerator nextObject])){
		if([arg caseInsensitiveCompare:@"BGCOLOR"] == NSOrderedSame){
			[textAttributes setBackgroundColor:[[inArgs objectForKey:arg] hexColor]];
		}
	}
}

- (void)processLinkTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator 	*enumerator;
	NSString		*arg;

	enumerator = [[inArgs allKeys] objectEnumerator];
	while((arg = [enumerator nextObject])){
		if([arg caseInsensitiveCompare:@"HREF"] == NSOrderedSame){
			[textAttributes setLinkURL:[inArgs objectForKey:arg]];
		}
	}
}

- (NSAttributedString *)processImgTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
	NSEnumerator				*enumerator;
	NSString					*arg;
	NSAttributedString			*attachString;
	NSFileWrapper				*fileWrapper = nil;
	NSString					*path = nil;
	AITextAttachmentExtension   *attachment = [[[AITextAttachmentExtension alloc] init] autorelease];

	enumerator = [inArgs keyEnumerator];
	while((arg = [enumerator nextObject])){
		if([arg caseInsensitiveCompare:@"SRC"] == NSOrderedSame){
			path = [inArgs objectForKey:arg];
			fileWrapper = [[[NSFileWrapper alloc] initWithPath:path] autorelease];
		}
		if([arg caseInsensitiveCompare:@"ALT"] == NSOrderedSame){
			[attachment setString:[inArgs objectForKey:arg]];
			[attachment setHasAlternate:YES];
		}
	}
	
	if (![attachment hasAlternate] && path) {
		[attachment setString:path];
	}
	
	[attachment setFileWrapper:fileWrapper];
	[attachment setShouldSaveImageForLogging:YES];
	attachString = [NSAttributedString attributedStringWithAttachment:attachment];
	return attachString;
}

//XXX - Currently always appends as png.  This is probably not always best as Windows DirectIM will not handle it.
- (BOOL)appendImage:(NSImage *)attachmentImage
		   toString:(NSMutableString *)string
		   withName:(NSString *)fileSafeChunk 
		  altString:(NSString *)attachmentString
		 imagesPath:(NSString *)imagesPath
{	
	NSString			*shortFileName;
	NSString			*fileName;
	NSString			*fileURL;	
	NSBitmapImageRep	*bitmapRep;
	BOOL				success = NO;
	
	bitmapRep = [NSBitmapImageRep imageRepWithData:[attachmentImage TIFFRepresentation]];
	shortFileName = [fileSafeChunk stringByAppendingPathExtension:@"png"];
	fileName = [imagesPath stringByAppendingPathComponent:shortFileName];
	fileURL = [[NSURL fileURLWithPath:fileName] absoluteString];
	
	//create the images directory if it doesn't exist
	[[NSFileManager defaultManager] createDirectoriesForPath:imagesPath];
	
	if([[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:fileName
																		  atomically:YES]){
		[string appendFormat:@"<img src=\"%@\" alt=\"%@\">", [fileURL stringByEscapingForHTML], [attachmentString stringByEscapingForHTML]];
		success = YES;
		
	}else{
		NSLog(@"failed to write log image");
	}

	return success;
}

- (void)appendFileTransferReferenceFromPath:(NSString *)path toString:(NSMutableString *)string
{
	[string appendFormat:@"<AdiumFT src=\"%@\">", [path stringByEscapingForHTML]];	
}

#pragma mark Accessors

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
	return thingsToInclude.attachmentImagesOnlyForSending;
}
- (void)setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:(BOOL)newValue
{
	thingsToInclude.attachmentImagesOnlyForSending = newValue;
}

- (BOOL)onlyUsesSimpleTags
{
	return thingsToInclude.simpleTagsOnly;
}
- (void)setOnlyUsesSimpleTags:(BOOL)newValue
{
	thingsToInclude.simpleTagsOnly = newValue;
}

- (BOOL)bodyBackground
{
	return thingsToInclude.bodyBackground;
}
- (void)bodyBackground:(BOOL)newValue
{
	thingsToInclude.bodyBackground = newValue;
}
@end

static AIHTMLDecoder *classMethodInstance = nil;

@implementation AIHTMLDecoder (ClassMethodCompatibility)

+ (AIHTMLDecoder *)classMethodInstance
{
	if(classMethodInstance == nil)
		classMethodInstance = [self new];
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
	classMethodInstance->thingsToInclude.attachmentImagesOnlyForSending = 
	classMethodInstance->thingsToInclude.simpleTagsOnly = 
	classMethodInstance->thingsToInclude.bodyBackground =
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
// attachmentImagesOnlyForSending: YES to only convert attachments to <IMG SRC="...> tags which should be sent to another user
// simpleTagsOnly: YES to separate out FONT tags and include only the most basic HTML elements
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
attachmentImagesOnlyForSending:(BOOL)attachmentImagesOnlyForSending
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
	classMethodInstance->thingsToInclude.attachmentImagesOnlyForSending = attachmentImagesOnlyForSending;
	classMethodInstance->thingsToInclude.simpleTagsOnly = simpleOnly;
	classMethodInstance->thingsToInclude.bodyBackground = bodyBackground;
	return [classMethodInstance encodeHTML:inMessage imagesPath:imagesPath];
}

+ (NSAttributedString *)decodeHTML:(NSString *)inMessage
{
	return [[self classMethodInstance] decodeHTML:inMessage];
}

+ (NSDictionary *)parseArguments:(NSString *)arguments
{
	return [[self classMethodInstance] parseArguments:arguments];
}

@end

#pragma mark C functions

int HTMLEquivalentForFontSize(int fontSize)
{
	if(fontSize <= 9){
		return(1);
	}else if(fontSize <= 10){
		return(2);
	}else if(fontSize <= 12){
		return(3);
	}else if(fontSize <= 14){
		return(4);
	}else if(fontSize <= 18){
		return(5);
	}else if(fontSize <= 24){
		return(6);
	}else{
		return(7);
	}
}
