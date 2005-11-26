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

#import "AIInterfaceController.h"
#import "ESMetaContactContentsPlugin.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIServiceIcons.h>

#define META_TOOLTIP_ICON_SIZE NSMakeSize(10,10)

/*!
 * @class ESMetaContactContentsPlugin
 * @brief Tooltip component: Show the contacts contained by metaContacts, with service and status state.
 */
@implementation ESMetaContactContentsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];	
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		return AILocalizedString(@"Contacts",nil);
	}
	
	return nil;
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSMutableAttributedString	*entry = nil;
	
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		NSArray				*listContacts = [(AIMetaContact *)inObject listContacts];
		
		//Only display the contents if it has more than one contact within it.
		if ([listContacts count] > 1) {
			NSMutableString	*entryString;
			AIListContact	*contact;
			NSEnumerator	*enumerator;
			BOOL			shouldAppendString = NO;
			
			entry = [[NSMutableAttributedString alloc] init];
			entryString = [entry mutableString];
			
			enumerator = [listContacts objectEnumerator];
			while ((contact = [enumerator nextObject])) {
				NSImage	*statusIcon, *serviceIcon;
				
				if (shouldAppendString) {
					[entryString appendString:@"\r"];
				} else {
					shouldAppendString = YES;
				}
				
				statusIcon = [[contact displayArrayObjectForKey:@"Tab Status Icon"] imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
				
				if (statusIcon) {
					NSTextAttachment		*attachment;
					NSTextAttachmentCell	*cell;
						
					cell = [[[NSTextAttachmentCell alloc] init] autorelease];
					[cell setImage:statusIcon];
					
					attachment = [[[NSTextAttachment alloc] init] autorelease];
					[attachment setAttachmentCell:cell];
					
					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				}
				
				[entryString appendString:[contact formattedUID]];
				
				serviceIcon = [[AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal]
									imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
				if (serviceIcon) {
					NSTextAttachment		*attachment;
					NSTextAttachmentCell	*cell;
					
					cell = [[[NSTextAttachmentCell alloc] init] autorelease];
					[cell setImage:serviceIcon];
					
					attachment = [[[NSTextAttachment alloc] init] autorelease];
					[attachment setAttachmentCell:cell];
					
					[entryString appendString:@" "];
					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
/*					AILog(@"Size of %@ is %@",[AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal],
						  NSStringFromSize([serviceIcon size]));*/
				}
			}
		}
	}
    
    return [entry autorelease];
}

@end
