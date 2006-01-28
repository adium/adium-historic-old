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
#import <AIUtilities/AIImageAdditions.h>

#include <Carbon/Carbon.h>

#define LEFT_MARGIN		5
#define IMAGE_MARGIN	4
#define ARROW_WIDTH		8
#define ARROW_HEIGHT	(ARROW_WIDTH/2.0)
#define ARROW_XOFFSET	5
#define RIGHT_MARGIN	5

@implementation AIContactListStatusMenuCell

- (void)commonInit
{
	title = nil;
	currentImage = nil;
	textSize = NSZeroSize;
	imageSize = NSZeroSize;

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
	[newCell->title retain];
	[newCell->currentImage retain];
	[newCell->statusParagraphStyle retain];
	[newCell->statusAttributes retain];
	
	return newCell;
}

- (void)dealloc
{	
	/* Super's implementation calls setImage:nil in 10.4; we shouldn't depend on this implementation detail but should
	 * set our ivars to nil to ensure we don't double-release.
	 */
	[title release]; title = nil;
	[currentImage release]; currentImage = nil;

	[statusParagraphStyle release];
	[statusAttributes release];

	[super dealloc];
}

- (void)setTitle:(NSString *)inTitleString
{
	[title release];

	//Strip out all newlines
	inTitleString = [inTitleString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

	title = [[NSMutableAttributedString alloc] initWithString:inTitleString
												   attributes:statusAttributes];
	textSize = [title size];
}

-(void)setImage:(NSImage *)inImage
{
	if (inImage != currentImage) {
		[currentImage release];
		currentImage = [inImage retain];
		
		imageSize = [currentImage size];
	}	
}

- (void)fadeHovered
{
	if (hovered) {
		if (hoveredFraction < 1.0) hoveredFraction += 0.05;
	} else {
		if (hoveredFraction > 0.0) hoveredFraction -= 0.05;
	}

	[[self controlView] display];

	if ((hoveredFraction > 0.0) &&
		(hoveredFraction < 1.0)) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(fadeHovered)
												   object:nil];
		
		[self performSelector:@selector(fadeHovered)
				   withObject:nil
				   afterDelay:0];
	}
}

- (void)setHovered:(BOOL)inHovered
{
	hovered = inHovered;
	
	hoveredFraction = (hovered ? 0.80 : 0.20);
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(fadeHovered)
											   object:nil];
	[self performSelector:@selector(fadeHovered)
			   withObject:nil
			   afterDelay:0];
}

#pragma mark Drawing

//for some unknown reason, NSButtonCell's -drawWithFrame:inView: draws a basic ridge border on the bottom-right if we do not override it.
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (float)trackingWidth
{
	float trackingWidth;
	
	trackingWidth = LEFT_MARGIN + [title size].width + ARROW_XOFFSET + ARROW_WIDTH + RIGHT_MARGIN;
	
	if (currentImage) {
		trackingWidth += imageSize.width + IMAGE_MARGIN;
	}
	
	return trackingWidth;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect	textRect;
	NSColor	*drawingColor;

	[statusParagraphStyle setMaximumLineHeight:cellFrame.size.height];

	textRect = NSMakeRect(cellFrame.origin.x + LEFT_MARGIN + imageSize.width + IMAGE_MARGIN,
						  cellFrame.origin.y + ((cellFrame.size.height - textSize.height) / 2),
						  textSize.width,
						  textSize.height);

	float maxTextWidth = (cellFrame.size.width - LEFT_MARGIN - ARROW_XOFFSET - ARROW_WIDTH - RIGHT_MARGIN);
	if (currentImage) {
		maxTextWidth -= (imageSize.width + IMAGE_MARGIN);
	}

	if (textRect.size.width > maxTextWidth) {
		textRect.size.width = maxTextWidth;
	}

	if (hovered || (hoveredFraction > 0.0)) {
		//Draw our hovered / highlighted background first
		NSBezierPath	*path;
		
		float backgroundWidth = LEFT_MARGIN + textRect.size.width + ARROW_XOFFSET + ARROW_WIDTH + RIGHT_MARGIN;
		
		if (currentImage) {
			backgroundWidth += imageSize.width + IMAGE_MARGIN;
		}

		path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(cellFrame.origin.x,
																  cellFrame.origin.y,
																  backgroundWidth,
																  cellFrame.size.height)
												radius:10];
		
		if ([self isHighlighted]) {
			[[[NSColor darkGrayColor] colorWithAlphaComponent:hoveredFraction] set];

		} else {
			[[[NSColor grayColor]  colorWithAlphaComponent:hoveredFraction] set];
		}

		[path fill];
		
		if (hovered) {
			drawingColor = [NSColor whiteColor];
		} else {
			drawingColor = [NSColor blackColor];
		}
	} else {
		drawingColor = [NSColor blackColor];
	}
	
	if (currentImage) {
		[currentImage drawInRect:NSMakeRect(cellFrame.origin.x + LEFT_MARGIN,
											cellFrame.origin.y,
											imageSize.width + IMAGE_MARGIN,
											cellFrame.size.height)
						  atSize:imageSize
						position:IMAGE_POSITION_LEFT
						fraction:1.0];
	}

	[statusAttributes setObject:drawingColor
						 forKey:NSForegroundColorAttributeName];
	[title setAttributes:statusAttributes
						   range:NSMakeRange(0, [title  length])];
	[title drawInRect:textRect];
	
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
