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
#define USER_ICON_SIZE			28
#define VERTICAL_ICON_PADDING	1
#define ICON_LEFT_PADDING 		4
#define ICON_RIGHT_PADDING 		1
#define ICON_TEXT_PADDING		3
#define SHOW_STATUS_ICON		YES
#define STATUS_ICON_ON_LEFT		NO
#define CONTACT_FONT 			[NSFont systemFontOfSize:11]

#define SHOW_EXTENDED_STATUS	YES
#define EXTENDED_STATUS_FONT	[NSFont systemFontOfSize:9]
#define EXTENDED_STATUS_COLOR	[NSColor grayColor]

#define badgewidth 				30

#define CONTACT_TEXT_ALIGN		NSLeftTextAlignment//NSCenterTextAlignment
//NSLeftTextAlignment		= 0, /* Visually left aligned */
//NSRightTextAlignment	= 1, /* Visually right aligned */
//NSCenterTextAlignment	= 2,

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactCell	*newCell = [[AIListContactCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}


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

	//Service badge
//	if(SHOW_STATUS_ICON){
//		if(STATUS_ICON_ON_LEFT){
//			iconRect = iconRect = NSMakeRect(rect.origin.x,
//											 rect.origin.y,
//											 badgewidth,
//											 rect.size.height);
//		}else{
//			iconRect = iconRect = NSMakeRect(rect.origin.x + rect.size.width - badgewidth,
//											 rect.origin.y,
//											 badgewidth,
//											 rect.size.height);
//		}
//		
//		[self drawUserServiceIconInRect:iconRect];
//		
//		if(STATUS_ICON_ON_LEFT) rect.origin.x += badgewidth;
//		rect.size.width -= badgewidth;
//	}

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

	if(SHOW_EXTENDED_STATUS){
		int	halfHeight = rect.size.height / 2;
		
		rect.origin.y += halfHeight;
		rect.size.height -= halfHeight;
		
		if(![self drawUserExtendedStatusInRect:rect]){
			rect.size.height += halfHeight;
		}
		
		rect.origin.y -= halfHeight;
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




//User Extended Status
- (BOOL)drawUserExtendedStatusInRect:(NSRect)inRect
{
	NSRange glyphRange;
	
	//Format string
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		EXTENDED_STATUS_COLOR, NSForegroundColorAttributeName,
		EXTENDED_STATUS_FONT, NSFontAttributeName,nil];
	
	NSString *string = [[listObject statusObjectForKey:@"StatusMessage"] string];
//	if(!string) string = @"Online";

	if(string){
		string = [string stringByTruncatingTailToWidth:inRect.size.width ];
		
		NSString *extStatus = [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
		
		
		[textStorage setAttributedString:extStatus];
		glyphRange = [layoutManager glyphRangeForBoundingRect:NSMakeRect(0,0,inRect.size.width,10) inTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange
									   atPoint:NSMakePoint(inRect.origin.x, inRect.origin.y)];
		return(YES);
	}
	return(NO);
}

//
- (void)drawUserServiceIconInRect:(NSRect)inRect
{
	NSImage 	*statusImage;
	
	//Get the status image
#warning using ghetto service menu icons for now
	statusImage = [[[[AIObject sharedAdiumInstance] accountController] accountWithObjectID:[(AIListContact *)listObject accountID]] menuImage];
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


//User Status Badge
- (void)drawUserStatusBadgeInRect:(NSRect)inRect
{
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
