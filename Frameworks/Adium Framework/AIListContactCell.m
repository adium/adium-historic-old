//
//  AIListContactCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//

#import "AIListContactCell.h"

#import "AIListLayoutWindowController.h"

#define FONT_HEIGHT_STRING		@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


#define ICON_TEXT_PADDING		3

#define NAME_STATUS_PAD			6

#define STATUS_ICON_LEFT_PAD			2
#define STATUS_ICON_RIGHT_PAD			3
#define HULK_CRUSH_FACTOR 1
 
@implementation AIListContactCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Init
- (id)init
{
    [super init];
	
	backgroundOpacity = 1.0;
	statusFont = [[NSFont systemFontOfSize:12] retain];
	
	return(self);
}
	
//Dealloc
- (void)dealloc
{
	[statusFont release];
	[super dealloc];
}


//Cell sizing and padding ----------------------------------------------------------------------------------------------
#pragma mark Cell sizing and padding
//Size our cell to fit our content
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];
	
	if(userIconVisible && userIconSize.height > labelFontHeight){
		return(NSMakeSize(0, size.height + userIconSize.height));
	}else{
		return(NSMakeSize(0, size.height + labelFontHeight));
	}
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
		if(userIconPosition == IMAGE_POSITION_LEFT) width += ICON_TEXT_PADDING;
	}	
	
	//Status icon
	if(statusIconsVisible &&
	   (statusIconPosition != LIST_POSITION_BADGE_LEFT && statusIconPosition != LIST_POSITION_BADGE_RIGHT)){
		width += [[self statusImage] size].width;
		if(statusIconPosition != IMAGE_POSITION_LOWER_LEFT && statusIconPosition != IMAGE_POSITION_LOWER_RIGHT)
			width += STATUS_ICON_LEFT_PAD + STATUS_ICON_RIGHT_PAD;
	}

	//Service icon
	if(serviceIconsVisible &&
	   (serviceIconsVisible != LIST_POSITION_BADGE_LEFT && serviceIconsVisible != LIST_POSITION_BADGE_RIGHT)){
		width += [[self serviceImage] size].width;
	}
	
	return(width + 1);
}


//Status Text ----------------------------------------------------------------------------------------------------------
#pragma mark Status Text
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
- (NSColor *)statusColor{
	return(statusColor);
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
			[self statusColor], NSForegroundColorAttributeName,
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
	[AIUserIcons setListUserIconSize:userIconSize];
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

//Text Font
- (void)setFont:(NSFont *)inFont
{
	NSDictionary		*attributes;
	NSAttributedString 	*labelString;
	
	[super setFont:inFont];
	
	//Calculate and cache the height of this font
	attributes = [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName];
	labelString = [[[NSAttributedString alloc] initWithString:FONT_HEIGHT_STRING attributes:attributes] autorelease];
	labelFontHeight = [labelString heightWithWidth:1e7];
}

//
- (void)setBackgroundColorIsStatus:(BOOL)isStatus
{
	backgroundColorIsStatus = isStatus;
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
	
	//Right
	if(statusIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if(serviceIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//User Icon [Right]
	if(userIconPosition == LIST_POSITION_RIGHT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//Far Right
	if(statusIconPosition == LIST_POSITION_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if(serviceIconPosition == LIST_POSITION_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//Extended Status
	BOOL	drawUnder = [self drawStatusBelowLabelInRect:rect];
	if(drawUnder) rect = [self drawUserExtendedStatusInRect:rect drawUnder:drawUnder];
	rect = [self drawDisplayNameWithFrame:rect];
	if(!drawUnder) rect = [self drawUserExtendedStatusInRect:rect drawUnder:drawUnder];
	
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor	*labelColor = [self labelColor];
	if(labelColor){
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
						position:position];
		if(position == IMAGE_POSITION_LEFT) rect.origin.x += ICON_TEXT_PADDING;
		
		//Badges
		drawRect = [image rectForDrawingInRect:inRect
										atSize:userIconSize
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
		rect = [image drawInRect:rect
						  atSize:NSMakeSize(0, 0)
						position:position];
	}
	return(rect);
}

//User Extended Status
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect drawUnder:(BOOL)drawUnder
{
	
	if(extendedStatusVisible && (drawUnder || [self textAlignment] != NSCenterTextAlignment)){
		NSString 	*string = [[listObject statusObjectForKey:@"StatusMessage"] string];
		
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
			
			NSAttributedString *extStatus = [[[NSAttributedString alloc] initWithString:string
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

//Contact label color
- (NSColor *)labelColor
{
	if(backgroundColorIsStatus){
		NSColor *labelColor = [listObject displayArrayObjectForKey:@"Label Color"];
		return([labelColor colorWithAlphaComponent:backgroundOpacity]);
	}else{
		return(nil);
	}
}

//Contact text color
- (NSColor *)textColor
{
	NSColor	*theTextColor = [listObject displayArrayObjectForKey:@"Text Color"];
	return(theTextColor ? theTextColor : [super textColor]);
}

//Contact user image - AIUserIcons should already have been informed of our desired size by setUserIconSize: above.
- (NSImage *)userIconImage
{
	return([AIUserIcons listUserIconForContact:(AIListContact *)listObject]);
}

//Contact status image
- (NSImage *)statusImage
{
	return([listObject displayArrayObjectForKey:@"Tab Status Icon"]);
}

//Contact service image
- (NSImage *)serviceImage
{
	return([AIServiceIcons serviceIconForObject:listObject type:AIServiceIconList direction:AIIconFlipped]);
}

//YES if our status should draw below the label text
- (BOOL)drawStatusBelowLabelInRect:(NSRect)rect
{
	return(labelFontHeight + statusFontHeight - HULK_CRUSH_FACTOR <= rect.size.height);
}

//No need to the grid if we have a status color to draw
- (BOOL)drawGridBehindCell
{
	return([self labelColor] == nil);
}

@end
