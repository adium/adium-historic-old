//
//  AIListContactCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactCell.h"

#import "AIListLayoutWindowController.h"

@implementation AIListContactCell



#define ICON_TEXT_PADDING		3
#define CONTACT_FONT 			[NSFont systemFontOfSize:11]

#define EXTENDED_STATUS_FONT	[NSFont systemFontOfSize:9]
#define EXTENDED_STATUS_COLOR	[NSColor grayColor]

#define NAME_STATUS_PAD			6


//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactCell	*newCell = [[AIListContactCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}

- (id)init
{
    [super init];
	
	backgroundOpacity = 1.0;
	
	return(self);
}
	





	
//Label color
- (NSColor *)labelColor
{
	NSColor *labelColor = [[listObject displayArrayForKey:@"Label Color"] objectValue];
	return([labelColor colorWithAlphaComponent:backgroundOpacity]);
}

- (void)setBackgroundOpacity:(float)inOpacity
{
	backgroundOpacity = inOpacity;
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

//Padding.  Gives our cell a bit of edge padding so the user icon and name do not touch the sides
//- (int)topPadding{
//	return([super topPadding] + 1);
//}
//- (int)bottomPadding{
//	return([super bottomPadding] + 1);
//}
- (int)leftPadding{
	return([super leftPadding] + 4);
}
- (int)rightPadding{
	return([super rightPadding] + 4);
}

//Draw using our contact's status color
- (NSColor *)textColor
{
	if([self isSelectionInverted]){
		return([super textColor]);
	}else{
		NSColor	*textColor = [[listObject displayArrayForKey:@"Text Color"] objectValue];
		return(textColor ? textColor : [NSColor blackColor]);
	}
}



//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Configure
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

//Element Positioning
- (void)setUserIconPosition:(LIST_POSITION)inPosition{
	userIconPosition = inPosition;
}
- (void)setStatusIconPosition:(LIST_POSITION)inPosition{
	statusIconPosition = inPosition;
}
- (void)setServiceIconPosition:(LIST_POSITION)inPosition{
	serviceIconPosition = inPosition;
}


//Images ---------------------------------------------------------------------------------------------------------------
#pragma mark Images
//
- (NSImage *)userIconImage
{
	NSImage	*image = [listObject userIcon];
	
	if(!image){
		if(!genericUserIcon) genericUserIcon = [[NSImage imageNamed:@"DefaultIcon" forClass:[self class]] retain];
		image = genericUserIcon;
	}
	
	return(image);
}

//
- (NSImage *)statusImage
{
#warning using tab status icons for now
	return([[listObject displayArrayForKey:@"Tab Status Icon"] objectValue]);
}

//
- (NSImage *)serviceImage
{
	return([[[[AIObject sharedAdiumInstance] accountController] accountWithObjectID:[(AIListContact *)listObject accountID]] menuImage]);
}






//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing


#define HULK_CRUSH_FACTOR 1

//Draw left or not?
#warning cache me pleaaaase
- (BOOL)weFitInRect:(NSRect)rect
{
	//Username
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]] autorelease];
	int		nameHeight = [attrString heightWithWidth:1e7];
	
	//status
	NSAttributedString *statusString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[NSDictionary dictionaryWithObject:EXTENDED_STATUS_FONT forKey:NSFontAttributeName]] autorelease];
	int		statusHeight = [statusString heightWithWidth:1e7];
	
	NSLog(@"%i %i",nameHeight,statusHeight);
	return(nameHeight + statusHeight - HULK_CRUSH_FACTOR <= rect.size.height);
}




//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	NSRect			iconRect;

#warning This is ghetto, deal with it :D
	//Far Left
	if(statusIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawStatusIconInRect:rect onLeft:YES];
	if(serviceIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawServiceIconInRect:rect onLeft:YES];
	
	//User Icon [Left]
	if(userIconPosition == LIST_POSITION_LEFT) rect = [self drawUserIconInRect:rect onLeft:YES];
	
	//Left
	if(statusIconPosition == LIST_POSITION_LEFT) rect = [self drawStatusIconInRect:rect onLeft:YES];
	if(serviceIconPosition == LIST_POSITION_LEFT) rect = [self drawServiceIconInRect:rect onLeft:YES];
	
	//Right
	if(statusIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawStatusIconInRect:rect onLeft:NO];
	if(serviceIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawServiceIconInRect:rect onLeft:NO];
	
	//User Icon [Right]
	if(userIconPosition == LIST_POSITION_RIGHT) rect = [self drawUserIconInRect:rect onLeft:NO];
	
	//Far Right
	if(statusIconPosition == LIST_POSITION_RIGHT) rect = [self drawStatusIconInRect:rect onLeft:NO];
	if(serviceIconPosition == LIST_POSITION_RIGHT) rect = [self drawServiceIconInRect:rect onLeft:NO];
	
	BOOL	weFit = [self weFitInRect:rect];
	
	//Extended Status
	if(weFit) rect = [self drawUserExtendedStatusInRect:rect drawUnder:YES];
	
	rect = [self drawDisplayNameWithFrame:rect];
	
	if(!weFit) rect = [self drawUserExtendedStatusInRect:rect drawUnder:NO];
	
}















//User Icon
- (NSRect)drawUserIconInRect:(NSRect)rect onLeft:(BOOL)onLeft
{
	if(userIconVisible){
		rect = [self drawImage:[self userIconImage]
						atSize:NSMakeSize(userIconSize, userIconSize)
						inRect:rect
						onLeft:onLeft];
		if(onLeft) rect.origin.x += ICON_TEXT_PADDING;
	}
	return(rect);
}

//Status Icon
- (NSRect)drawStatusIconInRect:(NSRect)rect onLeft:(BOOL)onLeft
{
	if(statusIconsVisible){
		rect = [self drawImage:[self statusImage]
						atSize:NSMakeSize(0, 0)
						inRect:rect
						onLeft:onLeft];
	}
	return(rect);
}

//Service Icon
- (NSRect)drawServiceIconInRect:(NSRect)rect onLeft:(BOOL)onLeft
{
	if(serviceIconsVisible){
		rect = [self drawImage:[self serviceImage]
						atSize:NSMakeSize(0, 0)
						inRect:rect
						onLeft:onLeft];
	}
	return(rect);
}

//User Extended Status
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect drawUnder:(BOOL)drawUnder
{
	if(extendedStatusVisible){
		NSString 	*string = [[listObject statusObjectForKey:@"StatusMessage"] string];
		NSRange 	glyphRange;
		
		//if(!string) string = @"Online";
		if(string){
			int	halfHeight = rect.size.height / 2;

			//Pad
			if(drawUnder){
				rect.origin.y += halfHeight;
				rect.size.height -= halfHeight;
			}else{
				rect.origin.x += NAME_STATUS_PAD;
				rect.size.width -= NAME_STATUS_PAD;
			}
			
			//Format string

			
			NSParagraphStyle	*paragraphStyle;
			
			//Attributes
			paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment lineBreakMode:NSLineBreakByTruncatingTail/*NSLineBreakByClipping*/];
				
			
			
			
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				EXTENDED_STATUS_COLOR, NSForegroundColorAttributeName,
				EXTENDED_STATUS_FONT, NSFontAttributeName,nil];
			
			
			if(string){
//				string = [string stringByTruncatingTailToWidth:rect.size.width ];
				
				NSString *extStatus = [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
				
//				[[NSColor orangeColor] set];
//				[NSBezierPath fillRect:rect];
				
#warning gaaaaaah
				NSAttributedString *statusString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[NSDictionary dictionaryWithObject:EXTENDED_STATUS_FONT forKey:NSFontAttributeName]] autorelease];
				int		statusHeight = [statusString heightWithWidth:1e7];

				
				
				
				int half = (rect.size.height - statusHeight) / 2.0;
				[extStatus drawInRect:NSMakeRect(rect.origin.x,
												 rect.origin.y + half,
												 rect.size.width,
												 rect.size.height - half)];
	
//				[textStorage setAttributedString:extStatus];
//				glyphRange = [layoutManager glyphRangeForBoundingRect:NSMakeRect(0,0,rect.size.width,10) inTextContainer:textContainer];
//				[layoutManager drawGlyphsForGlyphRange:glyphRange
//											   atPoint:NSMakePoint(rect.origin.x, rect.origin.y)];
			}
			
			if(drawUnder){
				rect.origin.y -= halfHeight;
			}
		}
	}
	return(rect);
}

//Draw an image, altering and returning the available destination rect
- (NSRect)drawImage:(NSImage *)image atSize:(NSSize)size inRect:(NSRect)rect onLeft:(BOOL)isOnLeft
{
	NSRect	drawRect;
	
	//If we're passed a 0,0 size, use the image's size
	if(size.width == 0 || size.height == 0) size = [image size];
	
	//Adjust
	if(isOnLeft){
		drawRect = NSMakeRect(rect.origin.x,
							  rect.origin.y + (rect.size.height - size.height) / 2.0,
							  size.width,
							  size.height);
	}else{
		drawRect = NSMakeRect(rect.origin.x + rect.size.width - size.width,
							  rect.origin.y + (rect.size.height - size.height) / 2.0,
							  size.width,
							  size.height);
	}
	
	//Draw
	[image setFlipped:![image isFlipped]];
	[image drawInRect:drawRect
			 fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
			operation:NSCompositeSourceOver
			 fraction:1.0];
	[image setFlipped:![image isFlipped]];
	
	if(isOnLeft) rect.origin.x += size.width;
	rect.size.width -= size.width;
	
	return(rect);
}

@end
