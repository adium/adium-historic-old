//
//  AIListContactCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactCell.h"

#import "AIListLayoutWindowController.h"

#define FONT_HEIGHT_STRING	@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


@implementation AIListContactCell


#define ICON_TEXT_PADDING		3

#define EXTENDED_STATUS_COLOR	[NSColor grayColor]

#define NAME_STATUS_PAD			6

#define STATUS_ICON_LEFT_PAD			2
#define STATUS_ICON_RIGHT_PAD			3

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

- (id)init
{
    [super init];
	
	backgroundOpacity = 1.0;
	statusFont = [[NSFont systemFontOfSize:12] retain];
	
	return(self);
}
	
- (void)dealloc
{
	[statusFont release];
	[super dealloc];
}




//Status Text ----------------------------------------------------------------------------------------------------------
//Font used to display status text
- (void)setStatusFont:(NSFont *)inFont
{
	if(inFont && inFont != statusFont){
		NSDictionary		*attributes;
		NSAttributedString 	*statusString;
		
		[statusFont release];
		statusFont = [inFont retain];

		//Calculate and cache the height of this font
		attributes = [NSDictionary dictionaryWithObject:[self statusFont] forKey:NSFontAttributeName];
		statusString = [[[NSAttributedString alloc] initWithString:FONT_HEIGHT_STRING attributes:attributes] autorelease];
		statusFontHeight = [statusString heightWithWidth:1e7];
		
		//Flush the status attributes cache
		[_statusAttributes release]; _statusAttributes = nil;
	}
}
- (NSFont *)statusFont{
	return(statusFont);
}

//Attributes for displaying the status string (Cached)
//Cache is flushed when alignment, color, or font is changed
- (NSDictionary *)statusAttributes
{
	if(!_statusAttributes){
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
																	 lineBreakMode:NSLineBreakByTruncatingTail];
		
		_statusAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
			paragraphStyle, NSParagraphStyleAttributeName,
			EXTENDED_STATUS_COLOR, NSForegroundColorAttributeName,
			[self statusFont], NSFontAttributeName,nil] retain];
	}
	
	return(_statusAttributes);
}

//Flush status attributes when alignment is changed
- (void)setTextAlignment:(NSTextAlignment)inAlignment
{
	[super setTextAlignment:inAlignment];
	[_statusAttributes release]; _statusAttributes = nil;
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
	
	if([self padToFlippy]){
		int leftPad = [super leftPadding];
		int flippy = [[controlView groupCell] flippyIndent];
		
		NSLog(@"%i + %i = %i",leftPad, flippy, leftPad + flippy);
#warning flippy indent already has the padding, so it is being applied twice
		return(leftPad + flippy);
	}else{
		return([super leftPadding] + 1);
	}
}
- (int)rightPadding{
	return([super rightPadding] + 3);
}

- (BOOL)padToFlippy{
	return((!statusIconsVisible || statusIconPosition != LIST_POSITION_FAR_LEFT) &&
		   (!statusIconsVisible || statusIconPosition != LIST_POSITION_LEFT) &&
		   (!serviceIconsVisible || serviceIconPosition != LIST_POSITION_FAR_LEFT ) &&
		   (!serviceIconsVisible || serviceIconPosition != LIST_POSITION_LEFT) &&
		   (!userIconVisible || userIconPosition != LIST_POSITION_LEFT));
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
	return([[(AIListContact *)listObject account] menuImage]);
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
	NSAttributedString *statusString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[NSDictionary dictionaryWithObject:[self statusFont] forKey:NSFontAttributeName]] autorelease];
	int		statusHeight = [statusString heightWithWidth:1e7];
	
	return(nameHeight + statusHeight - HULK_CRUSH_FACTOR <= rect.size.height);
}




//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	NSRect			iconRect;

#warning This is ghetto, deal with it :D
	//Far Left
	if(statusIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_LEFT];
	if(serviceIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//User Icon [Left]
	if(userIconPosition == LIST_POSITION_LEFT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//Left
	if(statusIconPosition == LIST_POSITION_LEFT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_LEFT];
	if(serviceIconPosition == LIST_POSITION_LEFT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//Right
	if(statusIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if(serviceIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//User Icon [Right]
	if(userIconPosition == LIST_POSITION_RIGHT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//Far Right
	if(statusIconPosition == LIST_POSITION_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if(serviceIconPosition == LIST_POSITION_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	BOOL	weFit = [self weFitInRect:rect];
	
	//Extended Status
	if(weFit) rect = [self drawUserExtendedStatusInRect:rect drawUnder:YES];
	
	rect = [self drawDisplayNameWithFrame:rect];
	
	if(!weFit) rect = [self drawUserExtendedStatusInRect:rect drawUnder:NO];
	
}















//User Icon
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position
{
	NSRect	rect = inRect;
	if(userIconVisible){
		NSImage *image = [self userIconImage];
		[image setFlipped:![image isFlipped]];
		rect = [image drawInRect:rect
						  atSize:NSMakeSize(userIconSize, userIconSize)
						position:position];
		[image setFlipped:![image isFlipped]];
		if(position == IMAGE_POSITION_LEFT) rect.origin.x += ICON_TEXT_PADDING;
		
		
		
		//BADGES
#warning baaaah
		NSRect	drawRect = [[self userIconImage] rectForDrawingInRect:inRect
																atSize:NSMakeSize(userIconSize, userIconSize)
															  position:position];
		if(statusIconPosition == LIST_POSITION_BADGE_LEFT)
			[self drawStatusIconInRect:drawRect position:IMAGE_POSITION_LOWER_LEFT];
		if(statusIconPosition == LIST_POSITION_BADGE_RIGHT)
			[self drawStatusIconInRect:drawRect position:IMAGE_POSITION_LOWER_RIGHT];
		if(serviceIconPosition == LIST_POSITION_BADGE_LEFT)
			[self drawServiceIconInRect:drawRect position:IMAGE_POSITION_LOWER_LEFT];
		if(serviceIconPosition == LIST_POSITION_BADGE_RIGHT)
			[self drawServiceIconInRect:drawRect position:IMAGE_POSITION_LOWER_RIGHT];
								
	}
	
	return(rect);
}

//Status Icon
- (NSRect)drawStatusIconInRect:(NSRect)rect position:(IMAGE_POSITION)position
{
	if(statusIconsVisible){
		BOOL	isBadge = (position == IMAGE_POSITION_LOWER_LEFT || position == IMAGE_POSITION_LOWER_RIGHT);
		
		if(!isBadge){
			if(position == IMAGE_POSITION_LEFT) rect.origin.x += STATUS_ICON_LEFT_PAD;
			rect.size.width -= STATUS_ICON_LEFT_PAD;
		}

		NSImage *image = [self statusImage];
		[image setFlipped:![image isFlipped]];
		rect = [image drawInRect:rect
						  atSize:NSMakeSize(0, 0)
						position:position];
		[image setFlipped:![image isFlipped]];
		
		if(!isBadge){
			if(position == IMAGE_POSITION_LEFT) rect.origin.x += STATUS_ICON_RIGHT_PAD;
			rect.size.width -= STATUS_ICON_RIGHT_PAD;
		}
	}
	return(rect);
}

//Service Icon
- (NSRect)drawServiceIconInRect:(NSRect)rect position:(IMAGE_POSITION)position
{
	if(serviceIconsVisible){
		NSImage *image = [self serviceImage];
		[image setFlipped:![image isFlipped]];
		rect = [image drawInRect:rect
						  atSize:NSMakeSize(0, 0)
						position:position];
		[image setFlipped:![image isFlipped]];
	}
	return(rect);
}

//User Extended Status
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect drawUnder:(BOOL)drawUnder
{
	if(extendedStatusVisible && (drawUnder || [self textAlignment] != NSCenterTextAlignment)){
		NSString 	*string = [[listObject statusObjectForKey:@"StatusMessage"] string];
		NSRange 	glyphRange;
		
		if(string){
			int	halfHeight = rect.size.height / 2;

			//Pad
			if(drawUnder){
				rect.origin.y += halfHeight;
				rect.size.height -= halfHeight;
			}else{
				if([self textAlignment] == NSLeftTextAlignment) rect.origin.x += NAME_STATUS_PAD;
				rect.size.width -= NAME_STATUS_PAD;
			}
			
			NSString *extStatus = [[[NSAttributedString alloc] initWithString:string
																   attributes:[self statusAttributes]] autorelease];
			
			//Alignment
			NSSize		nameSize = [extStatus size];
			NSRect		drawRect = rect;
			
			if(nameSize.width > drawRect.size.width) nameSize = rect.size;
			
			switch([self textAlignment]){
				case NSCenterTextAlignment:
					drawRect.origin.x += (drawRect.size.width - nameSize.width) / 2.0;
					break;
				case NSRightTextAlignment:
					drawRect.origin.x += (drawRect.size.width - nameSize.width);
					break;
				default:
					break;
			}
			
			int half = (drawRect.size.height - statusFontHeight) / 2.0;
			[extStatus drawInRect:NSMakeRect(drawRect.origin.x,
											 drawRect.origin.y + half,
											 drawRect.size.width,
											 drawRect.size.height - half)];
			
			if(drawUnder){
				rect.origin.y -= halfHeight;
			}
		}
	}
	return(rect);
}


@end
