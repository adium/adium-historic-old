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

/*!
 * @class CBActionSupportPlugin
 * @brief Simple outgoing content filter to turn "/me blah" into *blah*
 */
@implementation CBActionSupportPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
}

/*!
 * @brief Filter
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *ourMessage = nil;
    if (inAttributedString) {
        NSRange meRange = [[inAttributedString string] rangeOfString:@"/me "];
        
        if(meRange.location == 0 && meRange.length == 4)
        {
            ourMessage = [[inAttributedString mutableCopyWithZone:nil] autorelease];
            
            [ourMessage replaceCharactersInRange:meRange withString:@"*"];
            
            NSAttributedString *splat = [[NSAttributedString alloc] initWithString:@"*" 
                                                                        attributes:[ourMessage attributesAtIndex:0 
                                                                                                  effectiveRange:nil]];
            [ourMessage appendAttributedString:splat];
            [splat release];
        }
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