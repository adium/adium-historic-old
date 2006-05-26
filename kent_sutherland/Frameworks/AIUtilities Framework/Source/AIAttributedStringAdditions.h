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

/*!
 * @category NSMutableAttributedString(AIAttributedStringAdditions)
 * @brief Additions to NSMutableAttributedString
 *
 * These methods add string replacement, <tt>NSData</tt> conversion, color adjustment, and more.
 */
@interface NSMutableAttributedString (AIAttributedStringAdditions)
/*!
 * @brief Append a string and set its attributes
 *
 * Appends <b>aString</b>, setting its attributes to <b>attributes</b>
 * @param aString The string to append
 * @param attributes The attributes to use
 */
- (void)appendString:(NSString *)aString withAttributes:(NSDictionary *)attributes;

/*!
 * @brief Find and replace on an attributed string
 *
 * Operation is identical to <tt>NSMutableString</tt>'s method of the same name.  The replacement string has the attributes of the string it replaced.
 * @param target The string to search for
 * @param replacement The string with which to replace <b>target</b>
 * @param options Search options, as with NSMutableString's method
 * @param range The range in which to search
 * @return Returns the number of replacements made
 */
- (unsigned int)replaceOccurrencesOfString:(NSString *)target withString:(NSString*)replacement options:(unsigned)opts range:(NSRange)searchRange;

/*!
 * @brief Find and replace on an attributed string setting the attributes of the replacements
 *
 * Operation is identical to <tt>NSMutableString</tt>'s method of the same name.  The replacement string has the specified attributes.
 * @param target The string to search for
 * @param replacement The string with which to replace <b>target</b>
 * @param attributes The attributes to apply to <b>replacement</b> for each replacement
 * @param options Search options, as with NSMutableString's method
 * @param range The range in which to search
 * @return Returns the number of replacements made
 */
- (unsigned int)replaceOccurrencesOfString:(NSString *)target withString:(NSString*)replacement attributes:(NSDictionary*)attributes options:(unsigned)opts range:(NSRange)searchRange;

/*!
 * @brief Apply color adjustments for a background
 *
 * Adjust all colors in the attributed string so they are visible on the specified background
 * @param backgroundColor The background color
 */
- (void)adjustColorsToShowOnBackground:(NSColor *)backgroundColor;

/*!
 * @brief Apply color adjustments for a background
 *
 * Adjust all colors in the attributed string so they are visible on the background, adjusting brightness in a manner proportional to the original background
 * @param backgroundColor The background color
 */
- (void)adjustColorsToShowOnBackgroundRelativeToOriginalBackground:(NSColor *)backgroundColor;

/*!
 * @brief Apply link appearance attributes where appropriate
 *
 * Sets color and underline attributes for any areas with NSLinkAttributeName set
 */
- (void)addFormattingForLinks;			
@end

/*!
 * @category NSData(AIAppleScriptAdditions)
 * @brief Adds the ability to obtain an <tt>NSAttributedString</tt> from data.
 *
 * This category on <tt>NSData</tt> complements a method in the NSAttributedString(AIAttributedStringAdditions) category.
 */
@interface NSData (AIAttributedStringAdditions)

/*!
 * @brief Return an <tt>NSAttributedString</tt> from this data
 *
 * Return an <tt>NSAttributedString</tt> from this data. The data should have been created via -[NSAttributedString dataRepresentation].
 * @return An <tt>NSAttributedString</tt>
 */
- (NSAttributedString *)attributedString;
@end

@interface NSAttributedString (AIAttributedStringAdditions)
/*!
 * @brief Determine the height needed to display an NSAttributedString with certain attributes
 *
 * Returns the height which a string with <b>attributes</b> will require for drawing purposes
 * @param attributes An <tt>NSDictionary</tt> of attributes
 * @return The needed height, as a float
 */
+ (float)stringHeightForAttributes:(NSDictionary *)attributes;

/*!
 * @brief Determine the height needed for display at a width
 *
 * Returns the height need to display at the passed width
 * @param width The available width for display
 * @return The needed height, as a float
 */
- (float)heightWithWidth:(float)width;

/*!
 * @brief Encode to <tt>NSData</tt>
 *
 * Archives the <tt>NSAttributedString</tt> and returns <tt>NSData</tt> suitable for storage
 * @return The attributed string represented as <tt>NSData</tt>
 */
- (NSData *)dataRepresentation;

/*!
 * @brief Obtain an <tt>NSAttributedString</tt> from encoded data
 *
 * Retrieves an <tt>NSAttributedString</tt> from <tt>NSData</tt> created with -[NSAttributedString dataRepresentation]
 * @param The source <tt>NSData</tt>
 * @return The decoded <tt>NSAttributedString</tt>
 */
+ (NSAttributedString *)stringWithData:(NSData *)inData;

/*
 * @brief Generate an NSAttributedString without attachments
 *
 * Generate an NSAttributedString without attachments by substituting their string value if possible (if the attachment responds to @selector(string)), and if not, substituting a characteristic string.
 * @return An <tt>NSAttributedString</tt> without attachments; it may be identical to the original object.
 */
- (NSAttributedString *)attributedStringByConvertingAttachmentsToStrings;

/*
 * @brief Generate an NSAttributedString without links
 *
 * @return An autoreleased copy of the receiver with each link expanded to its URI.
 */
- (NSAttributedString *)attributedStringByConvertingLinksToStrings;

/*!
 * @brief Create a new NSAttributedString, apply link appearance attributes where appropriate
 *
 * Sets color and underline attributes for any areas with NSLinkAttributeName set and returns the resulting <tt>NSAttributedString</tt>
 * @return A formatted <tt>NSAttributedString</tt>
 */
- (NSAttributedString *)stringByAddingFormattingForLinks;

+ (NSAttributedString *)stringWithString:(NSString *)inString;
@end


