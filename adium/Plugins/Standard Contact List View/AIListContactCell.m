//
//  AIListContactCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactCell.h"


@implementation AIListContactCell

#define USER_ICON_SIZE			16
#define VERTICAL_ICON_PADDING	1
#define ICON_LEFT_PADDING 		4
#define ICON_RIGHT_PADDING 		2



#define badgewidth 				30

- (NSSize)cellSize
{
	return(NSMakeSize(0, USER_ICON_SIZE + (VERTICAL_ICON_PADDING * 2.0)));
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect inView:(NSView *)controlView
{
	//Indent
	rect.origin.x += ICON_LEFT_PADDING;
	rect.size.width -= ICON_LEFT_PADDING;
	
	//Draw the user image
	[self drawUserIconInRect:NSMakeRect(rect.origin.x,
										rect.origin.y + (rect.size.height - USER_ICON_SIZE) / 2.0,
										USER_ICON_SIZE,
										USER_ICON_SIZE)];
	rect.origin.x += USER_ICON_SIZE + ICON_RIGHT_PADDING;
	rect.size.width -= USER_ICON_SIZE + ICON_RIGHT_PADDING;

	//Status badge
	[self drawUserStatusBadgeInRect:NSMakeRect(rect.origin.x + rect.size.width - badgewidth,
											   rect.origin.y,
											   badgewidth,
											   rect.size.height)];
	rect.size.width -= badgewidth;
	
	[self drawDisplayNameWithFrame:rect inView:controlView];
}




//Draw the user icon
- (void)drawUserIconInRect:(NSRect)inRect
{
	NSImage	*image = [[listObject displayArrayForKey:KEY_USER_ICON] objectValue];
	if(!image) image = [self genericUserIcon];
	
	if(image){
		[image setFlipped:![image isFlipped]];
		[image drawInRect:inRect
				 fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
		[image setFlipped:![image isFlipped]];
	}
}

//Returns a generic image for users without an icon (Cached)
- (NSImage *)genericUserIcon
{
	if(!genericUserIcon) genericUserIcon = [[NSImage imageNamed:@"DefaultIcon" forClass:[self class]] retain];
	return(genericUserIcon);
}


//User Name
- (void)drawUserNameInRect:(NSRect)inRect
{
	
}


//User Extended Status
- (void)drawUserExtendedStatusInRect:(NSRect)inRect
{
	
}


//User Status Badge
- (void)drawUserStatusBadgeInRect:(NSRect)inRect
{
//	NSString	*statusName;
	NSImage 	*statusImage;
	
	//Get the status image
#warning using tab status icons for now
	statusImage = [[listObject displayArrayForKey:@"Tab Status Icon"] objectValue];
	[statusImage setFlipped:YES];
	
	//Draw the image centered in the badge rect
	NSSize	imageSize = [statusImage size];
	NSRect	centeredRect = NSMakeRect(inRect.origin.x + (inRect.size.width - imageSize.width) / 2.0,
									  inRect.origin.y + (inRect.size.height - imageSize.height) / 2.0,
									  imageSize.width,
									  imageSize.height);
	[statusImage drawInRect:centeredRect
				   fromRect:NSMakeRect(0,0,imageSize.width,imageSize.height)
				  operation:NSCompositeSourceOver
				   fraction:1.0];
}

@end
