/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIStringAdditions.h"

@interface AIHTMLDecoder : NSObject {
	struct AIHTMLDecoderOptionsBitField {
		unsigned reserved: 22;

		//these next ten members are derived from the arguments to
		//  +encodeHTML:::::::::::: in the old AIHTMLDecoder.
		unsigned headers: 1;
		unsigned fontTags: 1;
		unsigned closingFontTags: 1;
		unsigned colorTags: 1;
		unsigned styleTags: 1;

		unsigned nonASCII: 1;
		unsigned allSpaces: 1;
		unsigned attachmentTextEquivalents: 1;
		unsigned attachmentImagesOnlyForSending: 1;

		unsigned simpleTagsOnly: 1;
	} thingsToInclude;
}

#pragma mark Creation

//+decoder, +new, and -init all return an instance with all flags set to 0.

+ (AIHTMLDecoder *)decoder;

//convenience methods to get a decoder that's already been set up a certain way.

- (id)initWithHeaders:(BOOL)includeHeaders
			 fontTags:(BOOL)includeFontTags
		closeFontTags:(BOOL)closeFontTags
			colorTags:(BOOL)includeColorTags
			styleTags:(BOOL)includeStyleTags
	   encodeNonASCII:(BOOL)encodeNonASCII
		 encodeSpaces:(BOOL)encodeSpaces
	attachmentsAsText:(BOOL)attachmentsAsText
attachmentImagesOnlyForSending:(BOOL)attachmentImagesOnlyForSending
	   simpleTagsOnly:(BOOL)simpleOnly;

+ (AIHTMLDecoder *)decoderWithHeaders:(BOOL)includeHeaders
							 fontTags:(BOOL)includeFontTags
						closeFontTags:(BOOL)closeFontTags
							colorTags:(BOOL)includeColorTags
							styleTags:(BOOL)includeStyleTags
					   encodeNonASCII:(BOOL)encodeNonASCII
						 encodeSpaces:(BOOL)encodeSpaces
					attachmentsAsText:(BOOL)attachmentsAsText
	   attachmentImagesOnlyForSending:(BOOL)attachmentImagesOnlyForSending
					   simpleTagsOnly:(BOOL)simpleOnly;

#pragma mark Work methods

//turn HTML source into an attributed string.
//uses no options.
- (NSAttributedString *)decodeHTML:(NSString *)inMessage;

//turn an attributed string into HTML source.
//uses all options.
- (NSString *)encodeHTML:(NSAttributedString *)inMessage imagesPath:(NSString *)imagesPath;

//pass a string containing all the attributes of a tag (for example,
//  @"src=\"window.jp2\" alt=\"Window on the World\""). you will get back a
//  dictionary containing those attributes (for example, @{ @"src" =
//  @"window.jp2", @"alt" = @"Window on the World" }).
//uses no options.
- (NSDictionary *)parseArguments:(NSString *)arguments;

#pragma mark Accessors

//meaning <HTML> and </HTML>.
- (BOOL)includesHeaders;
- (void)setIncludesHeaders:(BOOL)newValue;

- (BOOL)includesFontTags;
- (void)setIncludesFontTags:(BOOL)newValue;

- (BOOL)closesFontTags;
- (void)setClosesFontTags:(BOOL)newValue;

- (BOOL)includesColorTags;
- (void)setIncludesColorTags:(BOOL)newValue;

//turn non-printable characters into entities.
- (BOOL)encodesNonASCII;
- (void)setEncodesNonASCII:(BOOL)newValue;

- (BOOL)preservesAllSpaces;
- (void)setPreservesAllSpaces:(BOOL)newValue;

- (BOOL)usesAttachmentTextEquivalents;
- (void)setUsesAttachmentTextEquivalents:(BOOL)newValue;

- (BOOL)onlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage;
- (void)setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:(BOOL)newValue;

- (BOOL)onlyUsesSimpleTags;
- (void)setOnlyUsesSimpleTags:(BOOL)newValue;

@end

@interface AIHTMLDecoder (ClassMethodCompatibility)

/*these bring back the class methods that I (boredzo) turned into instance
 *  methods for the sake of clarity.
 *when these methods are no longer used, this category should be deleted.
 */

+ (NSAttributedString *)decodeHTML:(NSString *)inMessage;
+ (NSString *)encodeHTML:(NSAttributedString *)inMessage encodeFullString:(BOOL)encodeFullString;

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
		  simpleTagsOnly:(BOOL)simpleOnly;

+ (NSDictionary *)parseArguments:(NSString *)arguments;

@end
