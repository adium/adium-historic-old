//
//  AIListContactCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactCell.h"


@implementation AIListContactCell

#define SHOW_USER_ICON			YES
#define USER_ICON_ON_LEFT		YES
#define USER_ICON_SIZE			20
#define VERTICAL_ICON_PADDING	1
#define ICON_LEFT_PADDING 		4
#define ICON_RIGHT_PADDING 		1
#define ICON_TEXT_PADDING		3
#define SHOW_STATUS_ICON		YES
#define STATUS_ICON_ON_LEFT		NO
#define CONTACT_FONT 			[NSFont systemFontOfSize:11]

#define badgewidth 				30

#define CONTACT_TEXT_ALIGN		NSRightTextAlignment //NSLeftTextAlignment
//NSLeftTextAlignment		= 0, /* Visually left aligned */
//NSRightTextAlignment	= 1, /* Visually right aligned */
//NSCenterTextAlignment	= 2,

- (NSFont *)font
{
	return(CONTACT_FONT);
}


- (NSTextAlignment)textAlignment
{
	return(CONTACT_TEXT_ALIGN);
}

- (NSSize)cellSize
{
	if(SHOW_USER_ICON){
		return(NSMakeSize(0, USER_ICON_SIZE + (VERTICAL_ICON_PADDING * 2)));
	}else{
		
#warning I hate OS X font sizing
		
NSAttributedString *		attrString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]] autorelease];
int		textHeight = [attrString heightWithWidth:1e7];

		return(NSMakeSize(0, /*(int)([[self font] boundingRectForFont].size.height)*/textHeight + (VERTICAL_ICON_PADDING * 2)));
	}
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	NSRect	iconRect;

	//Indent
	rect.origin.x += ICON_LEFT_PADDING;
	rect.size.width -= ICON_LEFT_PADDING;
	
	//Draw the user image
	if(SHOW_USER_ICON){
		if(USER_ICON_ON_LEFT){
			iconRect = NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - USER_ICON_SIZE) / 2.0,
								  USER_ICON_SIZE,
								  USER_ICON_SIZE);
		}else{
			iconRect = NSMakeRect(rect.origin.x + rect.size.width - ICON_RIGHT_PADDING - USER_ICON_SIZE,
								  rect.origin.y + (rect.size.height - USER_ICON_SIZE) / 2.0,
								  USER_ICON_SIZE,
								  USER_ICON_SIZE);
		}
		
		[self drawUserIconInRect:iconRect];

		if(USER_ICON_ON_LEFT) rect.origin.x += USER_ICON_SIZE + ICON_RIGHT_PADDING;
		if(USER_ICON_ON_LEFT) rect.origin.x += ICON_TEXT_PADDING;
		rect.size.width -= USER_ICON_SIZE + ICON_RIGHT_PADDING;
	}

	//Status badge
	if(SHOW_STATUS_ICON){
		if(STATUS_ICON_ON_LEFT){
			iconRect = iconRect = NSMakeRect(rect.origin.x,
											 rect.origin.y,
											 badgewidth,
											 rect.size.height);
		}else{
			iconRect = iconRect = NSMakeRect(rect.origin.x + rect.size.width - badgewidth,
											 rect.origin.y,
											 badgewidth,
											 rect.size.height);
		}
		
		[self drawUserStatusBadgeInRect:iconRect];

		if(STATUS_ICON_ON_LEFT) rect.origin.x += badgewidth;
		rect.size.width -= badgewidth;
	}
	
	[self drawDisplayNameWithFrame:rect];
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
