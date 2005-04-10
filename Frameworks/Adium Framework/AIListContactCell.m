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

#import "AIListContactCell.h"
#import "AIListLayoutWindowController.h"
#import "AIListObject.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIUserIcons.h>

#define NAME_STATUS_PAD			6

#define HULK_CRUSH_FACTOR 1


//Selections
#define CONTACT_INVERTED_TEXT_COLOR		[NSColor whiteColor]
#define CONTACT_INVERTED_STATUS_COLOR	[NSColor whiteColor]
#define SELECTED_IMAGE_OPACITY			0.8
#define FULL_IMAGE_OPACITY				1.0


@implementation AIListContactCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactCell *newCell = [super copyWithZone:zone];

	newCell->statusFont = [statusFont retain];
	newCell->statusColor = [statusColor retain];
	newCell->_statusAttributes = [_statusAttributes retain];
	newCell->_statusAttributesInverted = [_statusAttributesInverted retain];

	return(newCell);
}

//Init
- (id)init
{
    if((self = [super init]))
	{
		backgroundOpacity = 1.0;
		statusFont = [[NSFont systemFontOfSize:12] retain];
		statusColor = nil;
		_statusAttributes = nil;
		_statusAttributesInverted = nil;
		shouldUseContactTextColors = YES;
	}

	return self;
}
	
//Dealloc
- (void)dealloc
{
	[statusFont release];
	[statusColor release];
	
	[_statusAttributes release];
	[_statusAttributesInverted release];
	
	[super dealloc];
}


//Cell sizing and padding ----------------------------------------------------------------------------------------------
#pragma mark Cell sizing and padding
//Size our cell to fit our content
- (NSSize)cellSize
{
	int		largestElementHeight;
		
	//Display Name Height (And status text if below name)
	if(extendedStatusVisible && extendedStatusIsBelowName){
		largestElementHeight = labelFontHeight + statusFontHeight;
	}else{
		largestElementHeight = labelFontHeight;
	}
	
	//User Icon Height
	if(userIconVisible){
		if(userIconSize.height > largestElementHeight){
			largestElementHeight = userIconSize.height;
		}
	}
	
	//Status text height (If beside name)
	if(extendedStatusVisible && !extendedStatusIsBelowName){
		if(statusFontHeight > largestElementHeight){
			largestElementHeight = statusFontHeight;
		}
	}
	
	return(NSMakeSize(0, [super cellSize].height + largestElementHeight));
}

- (int)cellWidth
{
	int		width = [super cellWidth];
	
	//Name
	NSAttributedString	*displayName = [[[NSAttributedString alloc] initWithString:[self labelString]
																		attributes:[self labelAttributes]] autorelease];
	width += [displayName size].width;
	
	//User icon
	if(userIconVisible){
		width += userIconSize.width;
		width += USER_ICON_LEFT_PAD + USER_ICON_RIGHT_PAD;
	}
	
	//Status icon
	if(statusIconsVisible &&
	   (statusIconPosition != LIST_POSITION_BADGE_LEFT && statusIconPosition != LIST_POSITION_BADGE_RIGHT)){
		width += [[self statusImage] size].width;
		width += STATUS_ICON_LEFT_PAD + STATUS_ICON_RIGHT_PAD;
	}

	//Service icon
	if(serviceIconsVisible &&
	   (serviceIconPosition != LIST_POSITION_BADGE_LEFT && serviceIconPosition != LIST_POSITION_BADGE_RIGHT)){
		width += [[self serviceImage] size].width;
		width += SERVICE_ICON_LEFT_PAD + SERVICE_ICON_RIGHT_PAD;
	}
	
	return(width + 1);
}


//Status Text ----------------------------------------------------------------------------------------------------------
#pragma mark Status Text
//Font used to display status text
- (void)setStatusFont:(NSFont *)inFont
{
	[statusFont autorelease];
	statusFont = [inFont retain];
	
	//Calculate and cache the height of this font
	statusFontHeight = [NSAttributedString stringHeightForAttributes:[NSDictionary dictionaryWithObject:[self statusFont] forKey:NSFontAttributeName]];
	
	//Flush the status attributes cache
	[_statusAttributes release]; _statusAttributes = nil;
}
- (NSFont *)statusFont{
	return(statusFont);
}

//Color of status text
- (void)setStatusColor:(NSColor *)inColor
{
	if(statusColor != inColor){
		[statusColor release];
		statusColor = [inColor retain];

		//Flush the status attributes cache
		[_statusAttributes release]; _statusAttributes = nil;
	}
}
- (NSColor *)statusColor
{
	return(statusColor);
}

//Attributes for displaying the status string (Cached)
//Cache is flushed when alignment, color, or font is changed
- (NSDictionary *)statusAttributes
{
	if(!_statusAttributes){
		NSMutableParagraphStyle	*paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				lineBreakMode:NSLineBreakByTruncatingTail];
		[paragraphStyle setMaximumLineHeight:(float)labelFontHeight];
		
		_statusAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
			paragraphStyle, NSParagraphStyleAttributeName,
			[self statusColor], NSForegroundColorAttributeName,
			[self statusFont], NSFontAttributeName,nil] retain];
	}
	
	if(backgroundColorIsEvents && [[listObject displayArrayObjectForKey:@"Is Event"] boolValue]){
		//If we are showing a temporary event with a custom background color, use the standard text color
		//since it will be appropriate to the current background color.
		NSMutableDictionary	*mutableStatusAttributes = [_statusAttributes mutableCopy];
		[mutableStatusAttributes setObject:[self textColor]
									forKey:NSForegroundColorAttributeName];

		return([mutableStatusAttributes autorelease]);

	}else{
		return(_statusAttributes);
	}
}

- (NSDictionary *)statusAttributesInverted
{
	if(!_statusAttributesInverted){
		_statusAttributesInverted = [[self statusAttributes] mutableCopy];
		[_statusAttributesInverted setObject:CONTACT_INVERTED_STATUS_COLOR forKey:NSForegroundColorAttributeName];
	}
	
	return(_statusAttributesInverted);
}

//Flush status attributes when alignment is changed
- (void)setTextAlignment:(NSTextAlignment)inAlignment
{
	[super setTextAlignment:inAlignment];
	[_statusAttributes release]; _statusAttributes = nil;
}

	
//Display options ------------------------------------------------------------------------------------------------------
#pragma mark Display options
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
	userIconSize = NSMakeSize(inSize, inSize);
}
- (int)userIconSize{
	return(userIconSize.height);
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
- (void)setExtendedStatusIsBelowName:(BOOL)inBelowName{
	extendedStatusIsBelowName = inBelowName;
}
- (void)setUserIconPosition:(LIST_POSITION)inPosition{
	userIconPosition = inPosition;
}
- (void)setStatusIconPosition:(LIST_POSITION)inPosition{
	statusIconPosition = inPosition;
}
- (void)setServiceIconPosition:(LIST_POSITION)inPosition{
	serviceIconPosition = inPosition;
}

//Opacity
- (void)setBackgroundOpacity:(float)inOpacity
{
	backgroundOpacity = inOpacity;
}
- (float)backgroundOpacity{
	return(backgroundOpacity);
}

//
- (void)setBackgroundColorIsStatus:(BOOL)isStatus
{
	backgroundColorIsStatus = isStatus;
}
- (void)setBackgroundColorIsEvents:(BOOL)isEvents
{
	backgroundColorIsEvents = isEvents;
}

- (void)setShouldUseContactTextColors:(BOOL)flag
{
	shouldUseContactTextColors = flag;
}





//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	//Far Left
	if(statusIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_LEFT];
	if(serviceIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//User Icon [Left]
	if(userIconPosition == LIST_POSITION_LEFT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//Left
	if(statusIconPosition == LIST_POSITION_LEFT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_LEFT];
	if(serviceIconPosition == LIST_POSITION_LEFT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//Far Right
	if(statusIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if(serviceIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//User Icon [Right]
	if(userIconPosition == LIST_POSITION_RIGHT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//Right
	if(statusIconPosition == LIST_POSITION_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if(serviceIconPosition == LIST_POSITION_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//Extended Status
	if(extendedStatusIsBelowName) rect = [self drawUserExtendedStatusInRect:rect drawUnder:YES];
	rect = [self drawDisplayNameWithFrame:rect];
	if(!extendedStatusIsBelowName) rect = [self drawUserExtendedStatusInRect:rect drawUnder:NO];
	
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor	*labelColor = [self labelColor];
	if(labelColor && ![self cellIsSelected]){
		[labelColor set];
		[NSBezierPath fillRect:rect];
	}
}

//User Icon
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position
{
	NSRect	rect = inRect;
	if(userIconVisible){
		NSImage *image;
		NSRect	drawRect;
		
		image = [self userIconImage];
		if(!image) image = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconLarge direction:AIIconFlipped];
		
		rect = [image drawInRect:rect
						  atSize:userIconSize
						position:position
						fraction:[self imageOpacityForDrawing]];
		
		//If we're using space on the left, shift the origin right
		if(position == IMAGE_POSITION_LEFT) rect.origin.x += USER_ICON_LEFT_PAD;
		rect.size.width -= USER_ICON_LEFT_PAD;
		
		//Badges
		drawRect = [image rectForDrawingInRect:inRect
										atSize:userIconSize
									  position:position];
		if(statusIconPosition == LIST_POSITION_BADGE_LEFT){
			[self drawStatusIconInRect:drawRect position:IMAGE_POSITION_LOWER_LEFT];
		}else if(statusIconPosition == LIST_POSITION_BADGE_RIGHT){
			[self drawStatusIconInRect:drawRect position:IMAGE_POSITION_LOWER_RIGHT];
		}
		
		if(serviceIconPosition == LIST_POSITION_BADGE_LEFT){
			[self drawServiceIconInRect:drawRect position:IMAGE_POSITION_LOWER_LEFT];
		}else if(serviceIconPosition == LIST_POSITION_BADGE_RIGHT){
			[self drawServiceIconInRect:drawRect position:IMAGE_POSITION_LOWER_RIGHT];
		}
		
		//If we're using space on the right, shrink the width so we won't be overlapped
//		if(position == IMAGE_POSITION_RIGHT) rect.size.width -= USER_ICON_RIGHT_PAD;
		if(position == IMAGE_POSITION_LEFT) rect.origin.x += USER_ICON_RIGHT_PAD;
		rect.size.width -= USER_ICON_RIGHT_PAD;
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
						position:position
						fraction:1.0];
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
		BOOL	isBadge = (position == IMAGE_POSITION_LOWER_LEFT || position == IMAGE_POSITION_LOWER_RIGHT);

		if(!isBadge){
			if(position == IMAGE_POSITION_LEFT) rect.origin.x += SERVICE_ICON_LEFT_PAD;
			rect.size.width -= SERVICE_ICON_LEFT_PAD;
		}
		
		/*
		 Draw the service icon if (it is not a badge), or if (it is a badge and there is a userIconImage)
		 (We have already drawn the service icon if there is no userIconImage, in drawUserIconInRect:position:)
		 */
		if (!isBadge || ([self userIconImage] != nil)){
			NSImage *image = [self serviceImage];
			rect = [image drawInRect:rect
							  atSize:NSMakeSize(0, 0)
							position:position
							fraction:[self imageOpacityForDrawing]];
		}
		
		if(!isBadge){
			if(position == IMAGE_POSITION_LEFT) rect.origin.x += SERVICE_ICON_RIGHT_PAD;
			rect.size.width -= SERVICE_ICON_RIGHT_PAD;
		}
	}
	return(rect);
}

//User Extended Status
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect drawUnder:(BOOL)drawUnder
{
	if(extendedStatusVisible && (drawUnder || [self textAlignment] != NSCenterTextAlignment)){
		NSString 	*string = [listObject displayArrayObjectForKey:@"ExtendedStatus"];
		
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
			
			NSDictionary		*attributes = ([self cellIsSelected] ?
											   [self statusAttributesInverted] :
											   [self statusAttributes]);
			NSAttributedString 	*extStatus = [[NSAttributedString alloc] initWithString:string attributes:attributes];
			
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
			
			int half, offset;
			
			if(drawUnder){
				half = ceil((drawRect.size.height - statusFontHeight) / 2.0);
				offset = 0;
			}else{
				half = ceil((drawRect.size.height - labelFontHeight) / 2.0);
				offset = (labelFontHeight - statusFontHeight) + ([[self font] descender] - [[self statusFont] descender]);
			}

			[extStatus drawInRect:NSMakeRect(drawRect.origin.x,
											 drawRect.origin.y + half + offset,
											 drawRect.size.width,
											 drawRect.size.height - (half + offset))];

			[extStatus release];
			
			if(drawUnder){
				rect.origin.y -= halfHeight;
			}
		}
	}
	return(rect);
}

//Contact label color
- (NSColor *)labelColor
{
	BOOL	isEvent = [[listObject displayArrayObjectForKey:@"Is Event"] boolValue];
	
	if((isEvent && backgroundColorIsEvents) || (!isEvent && backgroundColorIsStatus)){
		NSColor		*labelColor = [listObject displayArrayObjectForKey:@"Label Color"];	
		NSNumber	*opacityNumber;
		float		targetOpacity = backgroundOpacity;
		
		//The backgroundOpacity is our eventual target; Temporary Display Opacity will be a fraction from 0 to 1 which
		//should be applied to that target
		if((opacityNumber = [listObject displayArrayObjectForKey:@"Temporary Display Opacity"])){
			targetOpacity *= [opacityNumber floatValue];
		}
		
		return((targetOpacity != 1.0) ? [labelColor colorWithAlphaComponent:targetOpacity] : labelColor);
	}else{
		return(nil);
	}
}

//Contact text color
- (NSColor *)textColor
{
	NSColor	*theTextColor;
	
	if (shouldUseContactTextColors && (theTextColor = [listObject displayArrayObjectForKey:@"Text Color"])){
		return(theTextColor);
	}else{
		return([super textColor]);
	}
}
- (NSColor *)invertedTextColor
{
	return(CONTACT_INVERTED_TEXT_COLOR/*[[self textColor] colorWithInvertedLuminance]*/);
}

//Contact user image - AIUserIcons should already have been informed of our desired size by setUserIconSize: above.
- (NSImage *)userIconImage
{
	return([AIUserIcons listUserIconForContact:(AIListContact *)listObject size:userIconSize]);
}

//Contact state or status image
- (NSImage *)statusImage
{
	NSImage *stateIcon = [listObject displayArrayObjectForKey:@"List State Icon"];
	if(!stateIcon) stateIcon = [listObject displayArrayObjectForKey:@"List Status Icon"];
	return(stateIcon);
}

//Contact service image
- (NSImage *)serviceImage
{
	return([AIServiceIcons serviceIconForObject:listObject type:AIServiceIconList direction:AIIconFlipped]);
}

//No need to the grid if we have a status color to draw
- (BOOL)drawGridBehindCell
{
	return([self labelColor] == nil);
}

//
- (float)imageOpacityForDrawing
{
	if([self cellIsSelected]){
		return(SELECTED_IMAGE_OPACITY);
	}else{
		NSNumber	*opacityNumber;
		if((opacityNumber = [listObject displayArrayObjectForKey:@"Temporary Display Opacity"])){
			return([opacityNumber floatValue]);
		}else{
			return([[listObject displayArrayObjectForKey:@"Image Opacity"] floatValue]);
		}
	}
}

@end
