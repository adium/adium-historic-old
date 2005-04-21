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

#import "AIContentController.h"
#import "CBActionSupportPlugin.h"
#import "AIInterfaceController.h"
#import "AIChat.h"
#import "AIAccount.h"

/*!
 * @class CBActionSupportPlugin
 * @brief Simple outgoing content filter to turn "/me blah" into "*blah*"
 */
@implementation CBActionSupportPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
}

/*output when YES: *Mac-arena the Bored Zo winks
 *output when NO:  *winks*
 *(note also the disappearance of the ending *.)
 *
 *this method can be overridden from a subclass (in a plug-in, for example), or
 *	modified in the future to read a preference.
 */
- (BOOL)includeDisplayNameInReplacement
{
	return NO;
}

/*!
 * @brief Filter
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	NSMutableAttributedString   *ourMessage = nil;
	
	if (inAttributedString && 
		[inAttributedString length] &&
		[[inAttributedString string] rangeOfString:@"/me"
										   options:NSLiteralSearch
											 range:NSMakeRange(0, [inAttributedString length])].location != NSNotFound) {
		NSMutableString *str;
		NSString		*startReplacement = @"*", *endReplacement = @"*";
		NSRange			extent;
		BOOL			includeDisplayName;
		unsigned		replacementLength;
		
		ourMessage = [[inAttributedString mutableCopyWithZone:[inAttributedString zone]] autorelease];
		str = [ourMessage mutableString];

		includeDisplayName = [self includeDisplayNameInReplacement];
		if(includeDisplayName) {
			startReplacement = [startReplacement stringByAppendingString:[[[[[adium interfaceController] activeChat] account] displayName] stringByAppendingString:@" "]];
			endReplacement = @"";
		}
		replacementLength = [startReplacement length] + [endReplacement length];

		extent = NSMakeRange(0, [str length]);
		do { //while(extent.length)
			NSRange lineRange, searchRange, meRange;
			signed shift = 0;
			unsigned endInsertPoint;
			
			lineRange = NSMakeRange(extent.location, 1);
			endInsertPoint = 0;
			[str getLineStart:&lineRange.location
			              end:&lineRange.length
			      contentsEnd:&endInsertPoint
			         forRange:lineRange];
			lineRange.length -= lineRange.location;
			
			searchRange = NSMakeRange(lineRange.location, endInsertPoint - lineRange.location);
			meRange = [str rangeOfString:@"/me " options:NSLiteralSearch range:searchRange];
			
			if(meRange.location == lineRange.location && meRange.length == 4) {
				NSAttributedString *endSplat = [[NSAttributedString alloc] initWithString:endReplacement 
																			attributes:[ourMessage attributesAtIndex:endInsertPoint-1
																									  effectiveRange:nil]];
				[ourMessage insertAttributedString:endSplat atIndex:endInsertPoint];
				[endSplat release];

				[ourMessage replaceCharactersInRange:meRange withString:startReplacement];

				shift = meRange.length - replacementLength;
			}
			
			shift += lineRange.length;
			if(shift > extent.length) shift = extent.length;
			extent.location += shift;
			extent.length   -= shift;
		} while(extent.length);
	}
	
	return (ourMessage ? ourMessage : inAttributedString);
}

/*!
 * @brief Filter priority
 */
- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

@end
