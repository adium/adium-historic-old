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

#import "ESMetaContactContentsPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#define META_TOOLTIP_ICON_SIZE NSMakeSize(11,11)

#define EXPAND_CONTACT		AILocalizedString(@"Expand combined contact", nil)
#define COLLAPSE_CONTACT	AILocalizedString(@"Collapse combined contact", nil)
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
	
	contextualMenuItem = [[NSMenuItem alloc] initWithTitle:EXPAND_CONTACT
													target:self
													action:@selector(toggleMetaContactExpansion:)
											 keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:contextualMenuItem
									   toLocation:Context_Contact_ListAction];
}

- (void)dealloc
{
	[contextualMenuItem release]; contextualMenuItem = nil;

	[super dealloc];
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
			BOOL			shouldAppendServiceIcon = ![(AIMetaContact *)inObject containsOnlyOneService];

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
						
					cell = [[NSTextAttachmentCell alloc] init];
					[cell setImage:statusIcon];
					
					attachment = [[NSTextAttachment alloc] init];
					[attachment setAttachmentCell:cell];
					[cell release];

					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
					[attachment release];
				}
				
				[entryString appendString:[contact formattedUID]];
				
				if (shouldAppendServiceIcon) {
					serviceIcon = [[AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal]
									imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
					if (serviceIcon) {
						NSTextAttachment		*attachment;
						NSTextAttachmentCell	*cell;
						
						cell = [[NSTextAttachmentCell alloc] init];
						[cell setImage:serviceIcon];
						
						attachment = [[NSTextAttachment alloc] init];
						[attachment setAttachmentCell:cell];
						[cell release];

						[entryString appendString:@" "];
						[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
						[attachment release];
					}
				}
			}
		}
	}
    
    return [entry autorelease];
}

#pragma mark Menu
- (void)toggleMetaContactExpansion:(id)sender
{
	AIListObject *listObject = [[adium menuController] currentContextMenuObject];
	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		BOOL currentlyExpandable = [(AIMetaContact *)listObject isExpandable];
		BOOL currentlyExpanded = [(AIMetaContact *)listObject isExpanded];
		
		if (currentlyExpandable && currentlyExpanded) {
			[[adium notificationCenter] postNotificationName:AIPerformCollapseItemNotification
													 object:listObject];
			[(AIMetaContact *)listObject setExpandable:NO];

		} else {
			[(AIMetaContact *)listObject setExpandable:YES];
			[[adium notificationCenter] postNotificationName:AIPerformExpandItemNotification
													 object:listObject];
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return ([[[adium menuController] currentContextMenuObject] isKindOfClass:[AIMetaContact class]]);
}

- (void)menu:(NSMenu *)menu needsUpdateForMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *listObject = [[adium menuController] currentContextMenuObject];
	if (menuItem == contextualMenuItem) {
		if ([listObject isKindOfClass:[AIMetaContact class]] &&
			[(AIMetaContact *)listObject containsMultipleContacts]) {
			BOOL currentlyExpandable = [(AIMetaContact *)listObject isExpandable];
			BOOL currentlyExpanded = [(AIMetaContact *)listObject isExpanded];
			
			if (currentlyExpandable && currentlyExpanded) {
				[menuItem setTitle:COLLAPSE_CONTACT];
			} else {
				[menuItem setTitle:EXPAND_CONTACT];				
			}
		} else {
			[menuItem setTitle:EXPAND_CONTACT];
		}
	}
}

@end
