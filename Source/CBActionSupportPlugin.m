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

#import <Adium/AIContentControllerProtocol.h>
#import "CBActionSupportPlugin.h"
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
/*!
 * @class CBActionSupportPlugin
 * @brief Simple content filter to turn "/me blah" into "<span class='actionMessageUserName'>Name of contact </span><span class="actionMessageBody">blah</span>"
 */
@implementation CBActionSupportPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[[adium contentController] registerHTMLContentFilter:self direction:AIFilterOutgoing];
	[[adium contentController] registerHTMLContentFilter:self direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterHTMLContentFilter:self];
}

#pragma mark -

/*!
 * @brief Filter
 */
- (NSString *)filterHTMLString:(NSString *)inHTMLString content:(AIContentObject*)content;
{	
	if ( inHTMLString && 
		[inHTMLString length] &&
		[[[content message] string] rangeOfString:@"/me"
										  options:NSLiteralSearch
											range:NSMakeRange(0, [[content message] length])].location == 0) {
		NSMutableString   *ourMessage = [inHTMLString mutableCopy];
		NSString *replacement = [NSString stringWithFormat:@"<span class='actionMessageUserName'>%@</span><span class='actionMessageBody'>", [[content source] displayName]];
		[ourMessage replaceCharactersInRange:[inHTMLString rangeOfString:@"/me"]
								  withString:replacement];
		[ourMessage appendString:@"</span>"];
		return ourMessage;
	}
	return inHTMLString;
}

/*!
 * @brief Filter priority
 */
- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

@end
