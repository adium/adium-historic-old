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

/*!
	@class AICompletingTextField
	@abstract A text field that auto-completes known strings
	@discussion A text field that auto-completes known strings. It supports a minimum string length before autocompletion as well as optionally completing any number of comma-separated strings.
*/
@interface AICompletingTextField : NSTextField {
    NSMutableSet			*stringSet;
	NSMutableDictionary		*impliedCompletionDictionary;
	
    int						minLength;
	BOOL					completeAfterSeparator;
    int						oldUserLength;
}

/*!
	@method setMinStringLength:
	@abstract Set the minimum string length before autocompletion
	@discussion Set the minimum string length before autocompletion.  The text field will not begin to autocomplete until the user has typed at least the specified number of characters.  Defaults to 1.
	@param length The new minimum length before autocompletion
*/
- (void)setMinStringLength:(int)length;

/*!
	@method setCompletesOnlyAfterSeparator:
	@abstract Set if the field should expect a comma-delimited series
	@discussion By default, the entire field will be a single autocompleting area; input text is checked in its entirety against specified possible completions.  If <b>split</b> is YES, however, the completions will be split at each comma, allowing a series of distinct comma-delimited autocompletions.
	@param split YES if the list should be treated as a comma-delimited series of autocompletions; NO if the entire field is a single autocompleting area
*/
- (void)setCompletesOnlyAfterSeparator:(BOOL)split;

/*!
	@method setCompletingStrings:
	@abstract Set all completions for the field.
	@discussion Set all possible completions for the field, overriding all previous completion settings. All completions are treated as literal completions. This does not just call addCompletionString: repeatedly; it is more efficient to use if you already have an array of completions.
	@param strings An <tt>NSArray</tt> of all completion strings
*/
- (void)setCompletingStrings:(NSArray *)strings;

/*!
	@method addCompletionString:
	@abstract Add a completion for the field.
	@discussion Add a literal completion for the field.
	@param string The completion to add.
*/
- (void)addCompletionString:(NSString *)string;

/*!
	@method addCompletionString:withImpliedCompletion:
	@abstract Add a completion for the field which displays and returns differently.
	@discussion Add a completion for the field.  <b>string</b> is the string which will complete for the user (so its beginning is what the user must type, and it is what the user will see in the field). <b>impliedCompletion</b> is what will be returned by <tt>impliedStringValue</tt> when <b>completion</b> is in the text field.
	@param string The visual completion to add.
	@param impliedCompletion The actual completion for <b>string</b>, which will be returned by <tt>impliedStringValue</tt> when <b>string</b> is in the text field.
*/
- (void)addCompletionString:(NSString *)string withImpliedCompletion:(NSString *)impliedCompletion;

/*!
	@method impliedStringValue
	@abstract Return the completed string value of the field
	@discussion Return the string value of the field, taking into account implied completions (see <tt>addCompletionString:withImpliedCompletion:</tt> for information on implied completions).
	@result	An <tt>NSString</tt> of the appropriate string value
*/
- (NSString *)impliedStringValue;

/*!
	@method impliedStringValueForString
	@abstract Return the implied string value the field has set for a passed string
	@discussion Returns the implied string value which the field has as the implied completion for <b>aString</b>. Useful while parsing multiple strings from the field when making using of multiple, comma-delimited items.
	@param aString The <tt>NSString</tt> to check for an implied completion
	@result	An <tt>NSString</tt> of the implied string value, or <b>aString</b> if no implied string value is assigned
*/
- (NSString *)impliedStringValueForString:(NSString *)aString;
@end
