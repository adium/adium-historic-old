//
//  AIListContactCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactCell.h"


@implementation AIListContactCell



#define USER_ICON_ON_LEFT		YES
#define ICON_TEXT_PADDING		3
#define STATUS_ICON_ON_LEFT		NO
#define CONTACT_FONT 			[NSFont systemFontOfSize:11]

#define EXTENDED_STATUS_FONT	[NSFont systemFontOfSize:9]
#define EXTENDED_STATUS_COLOR	[NSColor grayColor]

#define badgewidth 				30

#define CONTACT_TEXT_ALIGN		NSLeftTextAlignment

#define BACKGROUND_ALPHA		0.5

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactCell	*newCell = [[AIListContactCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}





//User Icon Visibility
- (void)setUserIconVisible:(BOOL)inShowIcon
{
	userIconVisible = inShowIcon;
}
- (BOOL)userIconVisible{
	return(userIconVisible);
}

//User Icon Size
- (void)setUserIconSize:(int)inSize
{
	userIconSize = inSize;
}
- (int)userIconSize{
	return(userIconSize);
}

//Extended Status Visibility
- (void)setExtendedStatusVisible:(BOOL)inShowStatus
{
	extendedStatusVisible = inShowStatus;
}
- (BOOL)extendedStatusVisible{
	return(extendedStatusVisible);
}

//Status Icon Visibility
- (void)setStatusIconsVisible:(BOOL)inShowStatus
{
	statusIconsVisible = inShowStatus;
}
- (BOOL)statusIconsVisible{
	return(statusIconsVisible);
}

//Service Icon Visibility
- (void)setServiceIconsVisible:(BOOL)inShowService
{
	serviceIconsVisible = inShowService;
}
- (BOOL)serviceIconsVisible{
	return(serviceIconsVisible);
}







//Padding.  Gives our cell a bit of edge padding so the user icon and name do not touch the sides
- (int)topPadding{
	return([super topPadding] + 1);
}
- (int)bottomPadding{
	return([super bottomPadding] + 1);
}
- (int)leftPadding{
	return([super leftPadding] + 4);
}
- (int)rightPadding{
	return([super rightPadding] + 4);
}










//Label color
- (NSColor *)labelColor
{
	NSColor *labelColor = [[listObject displayArrayForKey:@"Label Color"] objectValue];
	return([labelColor colorWithAlphaComponent:BACKGROUND_ALPHA]);
}



- (NSFont *)font
{
	return(CONTACT_FONT);
}


- (NSSize)cellSize
{
	NSSize	size = [super cellSize];
	
	if(userIconVisible){
		return(NSMakeSize(0, size.height + userIconSize));
	}else{
		
#warning I hate OS X font sizing ... cache this
		
NSAttributedString *		attrString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]] autorelease];
int		textHeight = [attrString heightWithWidth:1e7];

		return(NSMakeSize(0, /*(int)([[self font] boundingRectForFont].size.height)*/ size.height + textHeight));
	}
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	NSRect	iconRect;

	//Draw the user image
	if(userIconVisible){
		//Indent
//		rect.origin.x += ICON_LEFT_PADDING;
//		rect.size.width -= ICON_LEFT_PADDING;
		
		if(USER_ICON_ON_LEFT){
			iconRect = NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - userIconSize) / 2.0,
								  userIconSize,
								  userIconSize);
		}else{
			iconRect = NSMakeRect(rect.origin.x + rect.size.width - userIconSize,
								  rect.origin.y + (rect.size.height - userIconSize) / 2.0,
								  userIconSize,
								  userIconSize);
		}
		
		[self drawUserIconInRect:iconRect];

		if(USER_ICON_ON_LEFT) rect.origin.x += userIconSize;// + ICON_RIGHT_PADDING;
		if(USER_ICON_ON_LEFT) rect.origin.x += ICON_TEXT_PADDING;
//		rect.size.width -= userIconSize + ICON_RIGHT_PADDING;
	}

	//Service badge
	if(serviceIconsVisible){
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
		
		[self drawUserServiceIconInRect:iconRect];
		
		if(STATUS_ICON_ON_LEFT) rect.origin.x += badgewidth;
		rect.size.width -= badgewidth;
	}

	//Status badge
	if(statusIconsVisible){
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

	//Extended Status
	if(extendedStatusVisible){
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
	NSImage	*image = [listObject userIcon];
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
