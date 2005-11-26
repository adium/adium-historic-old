//
//  AIPlasticButtonCell.m
//  AIUtilities
//
//  Created by Mac-arena the Bored Zo on 2005-11-26.
//  Drawing code, -copyWithZone: code, -commonInit code, and -isOpaque ganked from previous implementation of AIPlasticButton by Adam Iser.
//

#import "AIPlasticButtonCell.h"
#import "AIImageAdditions.h"

#define LABEL_OFFSET_X	1
#define LABEL_OFFSET_Y	-1

#define IMAGE_OFFSET_X	0
#define IMAGE_OFFSET_Y	0

#define PLASTIC_ARROW_WIDTH		8
#define PLASTIC_ARROW_HEIGHT	(PLASTIC_ARROW_WIDTH/2.0)
#define PLASTIC_ARROW_XOFFSET	12
#define PLASTIC_ARROW_YOFFSET	12
#define PLASTIC_ARROW_PADDING	8

@interface AIPlasticButtonCell (PRIVATE)
- (NSImage *)popUpArrow;
@end

@implementation AIPlasticButtonCell

#pragma mark Birth and Death

//
- (id)copyWithZone:(NSZone *)zone
{
	AIPlasticButtonCell	*newCell = [[self class] allocWithZone:zone];
	NSCellType type = [self type];
	if(type == NSImageCellType)
		newCell = [newCell initImageCell:[self image]];
	else if(type == NSTextCellType)
		newCell = [newCell initTextCell:[self stringValue]];
	else
		newCell = [newCell init]; //and hope for the best

	[newCell setMenu:[[[self menu] copy] autorelease]];
	[newCell->plasticCaps retain];
	[newCell->plasticMiddle retain];
	[newCell->plasticPressedCaps retain];
	[newCell->plasticPressedMiddle retain];
	[newCell->plasticDefaultCaps retain];
	[newCell->plasticDefaultMiddle retain];

	return newCell;
}

- (void)commonInit
{
	//Default title and image
	[self setTitle:@""];
	[self setImage:nil];
	[self setImagePosition:NSImageOnly];

	Class myClass = [self class];

	//Load images
	plasticCaps          = [[NSImage imageNamed:@"PlasticButtonNormal_Caps"    forClass:myClass] retain];
	plasticMiddle        = [[NSImage imageNamed:@"PlasticButtonNormal_Middle"  forClass:myClass] retain];
	plasticPressedCaps   = [[NSImage imageNamed:@"PlasticButtonPressed_Caps"   forClass:myClass] retain];
	plasticPressedMiddle = [[NSImage imageNamed:@"PlasticButtonPressed_Middle" forClass:myClass] retain];
	plasticDefaultCaps   = [[NSImage imageNamed:@"PlasticButtonDefault_Caps"   forClass:myClass] retain];
	plasticDefaultMiddle = [[NSImage imageNamed:@"PlasticButtonDefault_Middle" forClass:myClass] retain];
	
	[plasticCaps          setFlipped:YES];
	[plasticMiddle        setFlipped:YES];
	[plasticPressedCaps   setFlipped:YES];
	[plasticPressedMiddle setFlipped:YES];
	[plasticDefaultCaps   setFlipped:YES];
	[plasticDefaultMiddle setFlipped:YES];
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

- (void)dealloc
{
    [plasticCaps release];
    [plasticMiddle release];
    [plasticPressedCaps release];
    [plasticPressedMiddle release];
    [plasticDefaultCaps release];
    [plasticDefaultMiddle release];    
	
	[popUpArrow release];
	
    [super dealloc];
}

#pragma mark Spiffy drawing magic

//for some unknown reason, NSButtonCell's -drawWithFrame:inView: draws a basic ridge border on the bottom-right if we do not override it.
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect	sourceRect, destRect, frame;
    int		capWidth;
    int		capHeight;
    int		middleRight;
    NSImage	*caps;
    NSImage	*middle;
	NSCellImagePosition imagePosition = [self imagePosition];
    
    //Get the correct images
    if (![self isHighlighted]) {
        if ([[self keyEquivalent] isEqualToString:@"\r"]) {
			//default button. draw appropriately.
            caps = plasticDefaultCaps;
            middle = plasticDefaultMiddle;
        } else {
            caps = plasticCaps;
            middle = plasticMiddle;
        }
    } else {
        caps = plasticPressedCaps;
        middle = plasticPressedMiddle;
    }

    //Precalc some sizes
    NSSize capsSize = [caps size];
    frame = cellFrame;//[controlView bounds];
    capWidth = capsSize.width / 2.0;
    capHeight = capsSize.height;
    middleRight = ((frame.origin.x + frame.size.width) - capWidth);

    //Draw the left cap
	destRect = NSMakeRect(frame.origin.x/* + capWidth*/, frame.origin.y/* + frame.size.height*/, capWidth, frame.size.height);
    [caps drawInRect:destRect
			fromRect:NSMakeRect(0, 0, capWidth, capHeight)
		   operation:NSCompositeSourceOver
			fraction:1.0];

    //Draw the middle, which tiles across the button (excepting the areas drawn by the left and right caps)
    NSSize middleSize = [middle size];
    sourceRect = NSMakeRect(0, 0, middleSize.width, middleSize.height);
    destRect = NSMakeRect(frame.origin.x + capWidth, frame.origin.y/* + frame.size.height*/, sourceRect.size.width,  frame.size.height);
	
    while (destRect.origin.x < middleRight && (int)destRect.size.width > 0) {
        //Crop
        if ((destRect.origin.x + destRect.size.width) > middleRight) {
            sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - middleRight;
        }
		
        [middle drawInRect:destRect
				  fromRect:sourceRect
				 operation:NSCompositeSourceOver
				  fraction:1.0];
        destRect.origin.x += destRect.size.width;
    }
	
    //Draw right mask
	destRect = NSMakeRect(middleRight, frame.origin.y/* + frame.size.height*/, capWidth, frame.size.height);
	[caps drawInRect:destRect
			fromRect:NSMakeRect(capWidth, 0, capWidth, capHeight)
		   operation:NSCompositeSourceOver
			fraction:1.0];
	
    //Draw Label
#warning XXX handle NSCellImagePosition values other than these two correctly
	NSLog(@"imagePosition is %u; NSImageOnly is %u", imagePosition, NSImageOnly);
	if(imagePosition != NSImageOnly) {
		NSString *title = [self title];
		if (title) {
			NSColor		*color;
			NSDictionary 	*attributes;
			NSSize		size;
			NSPoint		centeredPoint;

			//Prep attributes
			if ([self isEnabled]) {
				color = [NSColor blackColor];
			} else {
				color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
			}
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font], NSFontAttributeName, color, NSForegroundColorAttributeName, nil];

			//Calculate center
			size = [title sizeWithAttributes:attributes];
			centeredPoint = NSMakePoint(frame.origin.x + round((frame.size.width - size.width) / 2.0) + LABEL_OFFSET_X,
										frame.origin.y + round((frame.size.height - size.height) / 2.0) + LABEL_OFFSET_Y);

			//Draw
			[title drawAtPoint:centeredPoint withAttributes:attributes];
		}
    }

    //Draw image
	if(imagePosition != NSNoImage) {
		NSImage *image = [self image];
		if (image) {
			NSSize	size = [image size];
			NSRect	centeredRect;

			if ([self menu]) frame.size.width -= PLASTIC_ARROW_PADDING;

			centeredRect = NSMakeRect(frame.origin.x + (int)((frame.size.width - size.width) / 2.0) + IMAGE_OFFSET_X,
									  frame.origin.y + (int)((frame.size.height - size.height) / 2.0) + IMAGE_OFFSET_Y,
									  size.width,
									  size.height);

			[image setFlipped:YES];
			[image drawInRect:centeredRect
					 fromRect:NSMakeRect(0,0,size.width,size.height) 
					operation:NSCompositeSourceOver 
					 fraction:([self isEnabled] ? 1.0 : 0.5)];
		}
    }
    
	//Draw the arrow, if needed
	if ([self menu]) {
		//first create the arrow image if necessary.
		[self popUpArrow];

		NSRect srcRect = {
			NSZeroPoint,
			[popUpArrow size]
		};
		[popUpArrow drawAtPoint:NSMakePoint(NSWidth(frame)-PLASTIC_ARROW_XOFFSET, NSHeight(frame)-PLASTIC_ARROW_YOFFSET)
					   fromRect:srcRect
					  operation:NSCompositeSourceOver
					   fraction:0.7];
	}
}

#pragma mark Accessors (should that REALLY be plural?)

- (BOOL)isOpaque
{
    return NO;
}

#pragma mark UndocumentedGoodness (or: Here there be dragons)

//image for the little popup arrow (cached)
- (NSImage *)popUpArrow
{
	if (!popUpArrow) {
		NSBezierPath *arrowPath = [NSBezierPath bezierPath];

		/*  -----> x
		 * | 1---2
		 * |  \ /   1,2,3 = points
		 * v   3
		 * y
		 */
		[arrowPath moveToPoint:NSMakePoint(0, 1.0)];
		[arrowPath relativeLineToPoint:NSMakePoint( 1.0, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-0.5, 1.0)];
		[arrowPath closePath];

		popUpArrow = [[NSImage alloc] initWithSize:NSMakeSize(PLASTIC_ARROW_WIDTH, PLASTIC_ARROW_HEIGHT)];
		[popUpArrow setFlipped:YES];

		[popUpArrow lockFocus];
		[[NSColor blackColor] setFill];
		[arrowPath fill];
		[popUpArrow unlockFocus];
	}
	
	return popUpArrow;
}

@end
