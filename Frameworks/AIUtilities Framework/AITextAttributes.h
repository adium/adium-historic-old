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

#define AIBodyColorAttributeName	@"AIBodyColor"

/*!
	@class AITextAttributes
	@abstract Encapsulates attributes that can be applied to a block of text
	@discussion Allows easy modification of various attributes which can be applied to a block of texxt.  To use, simply use its -[AITextAttributes dictionary] method to return an <tt>NSDictionary</tt> suitable for passing to <tt>NSAttributedString</tt> or the like.
*/
@interface AITextAttributes : NSObject<NSCopying> {
    NSMutableDictionary	*dictionary;

    NSString			*fontFamilyName;
    NSFontTraitMask		fontTraitsMask;
    int					fontSize;
}

/*!
	@method textAttributesWithFontFamily:traits:size:
	@abstract Create a new <tt>AITextAttributes</tt> instance
	@discussion Create a new <tt>AITextAttributes</tt> instance.
	@param inFamilyName The family name for font attributes
	@param inTraits	<tt>NSFontTraitMask</tt> of initial traits.  Pass 0 for no traits.
	@param inSize Font point size
	@result The newly created (autoreleased) <tt>AITextAttributes</tt> object
*/
+ (id)textAttributesWithFontFamily:(NSString *)inFamilyName traits:(NSFontTraitMask)inTraits size:(int)inSize;

/*!
	@method dictionary
	@abstract Return the dictionary of attributes
	@discussion Return the dictionary of attributes of this <tt>AITextAttributes</tt> suitable for passing to <tt>NSAttributedString</tt> or the like.
	@result The <tt>NSDictionary</tt> of attributes
*/
- (NSDictionary *)dictionary;

/*!
	@method setFontFamily:
	@abstract Set the font family
	@discussion Set the font family
	@param inFamilyName The family name for font attributes
*/	 
- (void)setFontFamily:(NSString *)inFamilyName;

/*!
	@method setFontSize:
	@abstract Set the font size
	@discussion Set the font size
	@param inSize Font point size
*/	
- (void)setFontSize:(int)inSize;

/*!
	@method enableTrait:
	@abstract Add a trait to the current mask
	@discussion Add an <tt>NSFontTraitMask</tt> to the current mask of traits
	@param inTrait The <tt>NSFontTraitMask</tt> to add
*/
- (void)enableTrait:(NSFontTraitMask)inTrait;

/*!
	@method disableTrait:
	@abstract Remove a trait from the current mask
	@discussion Remove an <tt>NSFontTraitMask</tt> from the current mask of traits
	@param inTrait The <tt>NSFontTraitMask</tt> to remove
*/
- (void)disableTrait:(NSFontTraitMask)inTrait;

/*!
	@method setUnderline:
	@abstract Set the underline attribute
	@discussion Set the underline attribute
	@param inUnderline A BOOL of the new underline attribute
*/
- (void)setUnderline:(BOOL)inUnderline;

/*!
	@method setStrikethrough:
	@abstract Set the strikethrough attribute
	@discussion Set the strikethrough attribute
	@param inStrikethrough A BOOL of the new strikethrough attribute
*/
- (void)setStrikethrough:(BOOL)inStrikethrough;

/*!
	@method setSubscript:
	@abstract Set the subscript attribute
	@discussion Set the subscript attribute
	@param inSubscript A BOOL of the new subscript attribute
*/
- (void)setSubscript:(BOOL)inSubscript;

/*!
	@method setUnderline:
	@abstract Set the underline attribute
	@discussion Set the underline attribute
	@param inUnderline A BOOL of the new underline attribute
*/
- (void)setSuperscript:(BOOL)inSuperscript;

/*!
	@method setTextColor:
	@abstract Set the text foreground color
	@discussion Set  the text foreground color
	@param inColor A <tt>NSColor</tt> of the new text foreground color
*/
- (void)setTextColor:(NSColor *)inColor;

/*!
	@method setTextBackgroundColor:
	@abstract Set the text background color
	@discussion Set  the text background color
	@param inColor A <tt>NSColor</tt> of the new text background color
*/
- (void)setTextBackgroundColor:(NSColor *)inColor;

/*!
	@method setUnderline:
	@abstract Set the underline attribute
	@discussion Set the underline attribute
	@param inUnderline A BOOL of the new underline attribute
*/
- (void)setBackgroundColor:(NSColor *)inColor;

/*!
	@method setLinkURL:
	@abstract Set a link attribute
	@discussion Set a URL (as an <tt>NSString</tt>) to be associated with these attributes
	@param inURL An <tt>NSString</tt> of the link URL
*/
- (void)setLinkURL:(NSString *)inURL;

@end
