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

#import "JLPresenceRemote.h"
#import "JLStatusObject.h"
#import "AIStatus.h"
#import "AIStatusController.h"
#import "AIStatusMenu.h"
#import <AIUtilities/AIArrayAdditions.h>

@implementation JLPresenceRemote

- (id)init
{
	if ((self = [super init])) {
		statusObjectArray = [[NSMutableArray alloc] init];
		//accountObjectArray = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
	[statusObjectArray release];
	//[accountObjectArray release];
	
	[super dealloc];
}

- (NSMutableArray *)statusObjectArray
{
	return [[statusObjectArray mutableCopy] autorelease];
}

- (void)populateStatusObjects
{
	NSEnumerator			*enumerator;
	AIStatus				*statusState;
	JLStatusObject			*statusObject;
	AIStatusType			currentStatusType = AIAvailableStatusType;
	AIStatusMutabilityType	currentStatusMutabilityType = AILockedStatusState;
	
	[statusObjectArray removeAllObjects];
	
	// Sort states such that the same AIStatusType are grouped together
	enumerator = [[[adium statusController] sortedFullStateArray] objectEnumerator];
	while ((statusState = [enumerator nextObject])) {
		AIStatusType	thisStatusType = [statusState statusType];
		AIStatusType	thisStatusMutabilityType = [statusState mutabilityType];
		
		if ((currentStatusMutabilityType != AISecondaryLockedStatusState) &&
			(thisStatusMutabilityType == AISecondaryLockedStatusState)) {
			// FIXME: Add custom item, we are ending this group
		}
		
		// As far as the SMD is concerned invisible == away
		if (thisStatusType == AIInvisibleStatusType) 
			thisStatusType = AIAwayStatusType;
		
		// FIXME: Add custom item before adding new statusType
		if ((currentStatusType != thisStatusType) &&
			(currentStatusType != AIOfflineStatusType)) {
			// Don't include custom item if after secondary locked group as it's already included
			if ((currentStatusMutabilityType != AISecondaryLockedStatusState)) {
				
			}
			
			// FIXME: adda a divider
			
			currentStatusType = thisStatusType;
		}
		
		statusObject = [[JLStatusObject alloc] initWithTitle:[AIStatusMenu titleForMenuDisplayOfState:statusState]];
		
		if ([statusState isKindOfClass:[AIStatus class]]) {
			[statusObject setToolTip:[statusState statusMessageString]];
		} else {
			/* AIStatusGroup */
			[statusObject setHasSubmenu:YES];
			// FIXME: add the submenu too! 4/12 @
		}
		[statusObject setType:currentStatusType];
		[statusObject setImage:[statusState menuIcon]];
		[statusObjectArray addObject:statusObject];
		[statusObject release];
		
		currentStatusMutabilityType = thisStatusMutabilityType;
	}
	
	if (currentStatusType != AIOfflineStatusType) {
		// FIXME: Add last custom item.
	}
}

@end
