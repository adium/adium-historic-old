//
//  AIContactListStatusMenuCell.m
//  Adium
//
//  Created by Evan Schoenberg on 12/16/05.
//

#import "AIContactListStatusMenuCell.h"
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIColorAdditions.h>

#include <Carbon/Carbon.h>

#define LEFT_MARGIN		5
#define ARROW_WIDTH		8
#define ARROW_HEIGHT	(ARROW_WIDTH/2.0)
#define ARROW_XOFFSET	5
#define RIGHT_MARGIN	5

@implementation AIContactListStatusMenuCell

- (void)commonInit
{
	currentStatus = nil;
	
	statusParagraphStyle = [[NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
														  lineBreakMode:NSLineBreakByTruncatingTail] retain];
	
	statusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
		statusParagraphStyle, NSParagraphStyleAttributeName,
		[NSFont systemFontOfSize:10], NSFontAttributeName, 
		nil] retain];	
}

- (id)initTextCell:(NSString *)str
{
	if ((self = [super initTextCell:str])) {
		[self commonInit];
	}
	
	return self;    
}
- (id)initImageCell:(NSImage *)image
{
	if ((self = [super initImageCell:image])) {
		[self commonInit];
	}
	
	return self;    
}

- (id)copyWithZone:(NSZone *)zone
{
	AIContactListStatusMenuCell	*newCell = [[self class] allocWithZone:zone];

	switch ([self type]) {
		case NSImageCellType:
			newCell = [newCell initImageCell:[self image]];
			break;
		case NSTextCellType:
			newCell = [newCell initTextCell:[self stringValue]];
			break;
		default:
			newCell = [newCell init]; //and hope for the best
			break;
	}
	
	[newCell setMenu:[[[self menu] copy] autorelease]];
	[newCell->currentStatus retain];
	[newCell->statusParagraphStyle retain];
	[newCell->statusAttributes retain];
	
	return newCell;
}

- (void)dealloc
{
	[currentStatus release];
	[statusParagraphStyle release];
	[statusAttributes release];

	[super dealloc];
}

/*
 * @brief Set the name of the current status
 */
- (void)setCurrentStatusName:(NSString *)inStatusName
{
	[currentStatus release];
	
	currentStatus = [[NSMutableAttributedString alloc] initWithString:inStatusName
														   attributes:statusAttributes];
}

- (void)setHovered:(BOOL)inHovered
{
	hovered = inHovered;
}

#pragma mark Drawing

//for some unknown reason, NSButtonCell's -drawWithFrame:inView: draws a basic ridge border on the bottom-right if we do not override it.
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (float)trackingWidth
{
	return LEFT_MARGIN + [currentStatus size].width + ARROW_XOFFSET + ARROW_WIDTH + RIGHT_MARGIN;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect	textRect;
	NSSize	textSize;
	NSColor	*drawingColor;

	[statusParagraphStyle setMaximumLineHeight:cellFrame.size.height];

	textSize = [currentStatus size];

	textRect = NSMakeRect(cellFrame.origin.x + LEFT_MARGIN,
						  cellFrame.origin.y + ((cellFrame.size.height - textSize.height) / 2),
						  textSize.width,
						  textSize.height);

	if (textRect.size.width > (cellFrame.size.width - LEFT_MARGIN - ARROW_XOFFSET - ARROW_WIDTH - RIGHT_MARGIN)) {
		textRect.size.width = (cellFrame.size.width - LEFT_MARGIN - ARROW_XOFFSET - ARROW_WIDTH - RIGHT_MARGIN);
	}

	if (hovered) {
		NSBezierPath	*path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(cellFrame.origin.x,
																				   cellFrame.origin.y,
																				   LEFT_MARGIN + textRect.size.width + ARROW_XOFFSET + ARROW_WIDTH + RIGHT_MARGIN,
																				   cellFrame.size.height)
																 radius:10];
		
		if ([self isHighlighted]) {
			[[NSColor darkGrayColor] set];

		} else{
			[[NSColor grayColor] set];
		}
		
		[path fill];
		drawingColor = [NSColor whiteColor];

	} else {
		drawingColor = [NSColor blackColor];
	}
	

	[statusAttributes setObject:drawingColor
						 forKey:NSForegroundColorAttributeName];
	[currentStatus setAttributes:statusAttributes
						   range:NSMakeRange(0, [currentStatus  length])];
	[currentStatus drawInRect:textRect];
	
	//Draw the arrow
	NSBezierPath *arrowPath = [NSBezierPath bezierPath];
	
	[arrowPath moveToPoint:NSMakePoint(NSMaxX(textRect) + ARROW_XOFFSET, 
									   (NSMaxY(cellFrame) / 2) - (ARROW_HEIGHT / 2))];
	[arrowPath relativeLineToPoint:NSMakePoint(ARROW_WIDTH, 0)];
	[arrowPath relativeLineToPoint:NSMakePoint(-(ARROW_WIDTH/2), (ARROW_HEIGHT))];
	
	[drawingColor set];
	[arrowPath fill];
}

- (BOOL)isOpaque
{
    return NO;
}

@end
