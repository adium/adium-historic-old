//
//  AIListContactCell.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListCell.h"

@interface AIListContactCell : AIListCell {
	BOOL		userIconVisible;
	BOOL		extendedStatusVisible;
	BOOL		statusIconsVisible;
	BOOL		serviceIconsVisible;
	int			userIconSize;
}

- (void)drawUserIconInRect:(NSRect)inRect;
- (NSImage *)genericUserIcon;
- (void)drawUserNameInRect:(NSRect)inRect;
- (void)drawUserExtendedStatusInRect:(NSRect)inRect;
- (void)drawUserStatusBadgeInRect:(NSRect)inRect;

@end
