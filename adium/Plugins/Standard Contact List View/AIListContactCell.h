//
//  AIListContactCell.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListCell.h"
#import "AIListLayoutWindowController.h"

@interface AIListContactCell : AIListCell {
	BOOL		userIconVisible;
	BOOL		extendedStatusVisible;
	BOOL		statusIconsVisible;
	BOOL		serviceIconsVisible;
	int			userIconSize;
	
	BOOL		userIconPosition;
	BOOL		statusIconPosition;
	BOOL		serviceIconPosition;
	
	float		backgroundOpacity;
}

- (void)drawContentWithFrame:(NSRect)rect;
- (NSRect)drawUserIconInRect:(NSRect)rect onLeft:(BOOL)onLeft;
- (NSRect)drawStatusIconInRect:(NSRect)rect onLeft:(BOOL)onLeft;
- (NSRect)drawServiceIconInRect:(NSRect)rect onLeft:(BOOL)onLeft;
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect drawUnder:(BOOL)drawUnder;
- (NSRect)drawImage:(NSImage *)image atSize:(NSSize)size inRect:(NSRect)rect onLeft:(BOOL)isOnLeft;

- (NSImage *)userIconImage;
- (NSImage *)statusImage;
- (NSImage *)serviceImage;

- (void)setUserIconPosition:(LIST_POSITION)inPosition;
- (void)setStatusIconPosition:(LIST_POSITION)inPosition;
- (void)setServiceIconPosition:(LIST_POSITION)inPosition;

- (void)setBackgroundOpacity:(float)inOpacity;

@end
