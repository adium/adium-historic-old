//
//  AIPlasticButton.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 26 2003.
//

#import "AIPlasticButton.h"

#define LABEL_OFFSET_X	1
#define LABEL_OFFSET_Y	-1

#define IMAGE_OFFSET_X	0
#define IMAGE_OFFSET_Y	0

@implementation AIPlasticButton

//
- (id)copyWithZone:(NSZone *)zone
{
	AIPlasticButton	*newButton = [[[self class] allocWithZone:zone] initWithFrame:[self frame]];
	
	[newButton setMenu:[[[self menu] copy] autorelease]];
	
	return(newButton);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    //Default title and image
    [self setTitle:@""];
    [self setImage:nil];
    
    //Load images
    plasticCaps = [[NSImage imageNamed:@"PlasticButtonNormal_Caps" forClass:[self class]] retain];
    plasticMiddle = [[NSImage imageNamed:@"PlasticButtonNormal_Middle" forClass:[self class]] retain];
    plasticPressedCaps = [[NSImage imageNamed:@"PlasticButtonPressed_Caps" forClass:[self class]] retain];
    plasticPressedMiddle = [[NSImage imageNamed:@"PlasticButtonPressed_Middle" forClass:[self class]] retain];
    plasticDefaultCaps = [[NSImage imageNamed:@"PlasticButtonDefault_Caps" forClass:[self class]] retain];
    plasticDefaultMiddle = [[NSImage imageNamed:@"PlasticButtonDefault_Middle" forClass:[self class]] retain];

    return(self);    
}

- (void)drawRect:(NSRect)rect
{
    NSRect	sourceRect, destRect, frame;
    int		capWidth;
    int		capHeight;
    int		middleRight;
    NSImage	*caps;
    NSImage	*middle;
    
    //Get the correct images
    if(![[self cell] isHighlighted]){
        if([[self keyEquivalent] isEqualToString:@"\r"]){
            caps = plasticDefaultCaps;
            middle = plasticDefaultMiddle;
        }else{
            caps = plasticCaps;
            middle = plasticMiddle;
        }
    }else{
        caps = plasticPressedCaps;
        middle = plasticPressedMiddle;
    }

    //Precalc some sizes
    frame = [self bounds];
    capWidth = [caps size].width / 2.0;
    capHeight = [caps size].height;
    middleRight = ((frame.origin.x + frame.size.width) - capWidth);

    //Draw the left cap
    [caps compositeToPoint:NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height)
                  fromRect:NSMakeRect(0, 0, capWidth, capHeight)
                 operation:NSCompositeSourceOver];

    //Draw the middle
    sourceRect = NSMakeRect(0, 0, [middle size].width, [middle size].height);
    destRect = NSMakeRect(frame.origin.x + capWidth, frame.origin.y + frame.size.height, sourceRect.size.width, sourceRect.size.height);

    while(destRect.origin.x < middleRight && (int)destRect.size.width > 0){
        //Crop
        if((destRect.origin.x + destRect.size.width) > middleRight){
            sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - middleRight;
        }

        [middle compositeToPoint:destRect.origin
                        fromRect:sourceRect
                       operation:NSCompositeSourceOver];
        destRect.origin.x += destRect.size.width;
    }

    //Draw right mask
    [caps compositeToPoint:NSMakePoint(middleRight, frame.origin.y + frame.size.height)
                  fromRect:NSMakeRect(capWidth, 0, capWidth, capHeight)
                 operation:NSCompositeSourceOver];

    //Draw Label
    if([self title]){
        NSColor		*color;
        NSDictionary 	*attributes;
        NSSize		size;
        NSPoint		centeredPoint;

        //Prep attributes
        if([self isEnabled]){
            color = [NSColor blackColor];
        }else{
            color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
        }
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font], NSFontAttributeName, color, NSForegroundColorAttributeName, nil];

        //Calculate center
        size = [[self title] sizeWithAttributes:attributes];
        centeredPoint = NSMakePoint(frame.origin.x + ((frame.size.width - size.width) / 2.0) + LABEL_OFFSET_X,
                                    frame.origin.y + ((capHeight - size.height) / 2.0) + LABEL_OFFSET_Y);

        //Draw
        [[self title] drawAtPoint:centeredPoint withAttributes:attributes];
    }

    //Draw
    if([self image]){
        NSSize	size = [[self image] size];
        NSRect	centeredRect;

        centeredRect = NSMakeRect(frame.origin.x + (int)((frame.size.width - size.width) / 2.0) + IMAGE_OFFSET_X,
                                  frame.origin.y + (int)((capHeight - size.height) / 2.0) + IMAGE_OFFSET_Y,
                                  size.width,
                                  size.height);

        [[self image] setFlipped:YES];
        [[self image] drawInRect:centeredRect
						fromRect:NSMakeRect(0,0,size.width,size.height) 
					   operation:NSCompositeSourceOver 
						fraction:([self isEnabled] ? 1.0 : 0.5)];
    }
    
}

//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our menu and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	if(![self menu]){
		[super mouseDown:theEvent];
	}else{
		if([self isEnabled]){
			[self highlight:YES];
			
			NSPoint point = [self convertPoint:[self bounds].origin toView:nil];
			point.y -= NSHeight([self frame]) + 2;
			point.x -= 1;
			
			NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
												location:point
										   modifierFlags:[theEvent modifierFlags]
											   timestamp:[theEvent timestamp]
											windowNumber:[[theEvent window] windowNumber]
												 context:[theEvent context]
											 eventNumber:[theEvent eventNumber]
											  clickCount:[theEvent clickCount]
												pressure:[theEvent pressure]];
			[NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
			
			[self mouseUp:[[NSApplication sharedApplication] currentEvent]];
		}
	}
}

//Remove highlight on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];
	[super mouseUp:theEvent];
}

//Ignore dragging
- (void)mouseDragged:(NSEvent *)theEvent
{
	//Empty
}

- (BOOL)isOpaque
{
    return(NO);
}

- (void)dealloc
{
    [plasticCaps release];
    [plasticMiddle release];
    [plasticPressedCaps release];
    [plasticPressedMiddle release];
    [plasticDefaultCaps release];
    [plasticDefaultMiddle release];    

    [super dealloc];
}

@end
