/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

#import "AIEmoticonPackCell.h"
#import "AIEmoticonPack.h"
#import "AIEmoticon.h"
#import "AIEmoticonsPlugin.h"

@implementation AIEmoticonPackCell

#define EMOTICON_MAX_SIZE           20
#define EMOTICON_SPACING            4

#define EMOTICON_LEFT_MARGIN        2		//Left padding of cell
#define EMOTICON_NAME_SPACING		-3		//Space between checkbox and pack name
#define EMOTICON_ICON_INDENT		17		//Indent of preview icons

#define EMOTICON_RIGHT_MARGIN      	4

#define EMOTICON_BOTTOM_MARGIN      4
#define EMOTICON_TOP_MARGIN         0

static  float   distanceBetweenEmoticons = 0;

- (id)initWithPlugin:(id)inPlugin
{
	if (self = [super init]) {
		
		packCheckCell = [[NSButtonCell alloc] init];
		[packCheckCell setButtonType:NSSwitchButton];
		[packCheckCell setControlSize:NSSmallControlSize];
		[packCheckCell setTitle:@""];
		[packCheckCell setRefusesFirstResponder:YES];
		
		plugin = inPlugin;
	}
	return self;
}

//Drawing cells actually makes copies and deallocs them rapidly; rather than creating a new packCheckCell each time
//we reuse the same instance
- (id)copyWithZone:(NSZone*)zone
{
	AIEmoticonPackCell *newCell = [super copyWithZone:zone];
	
	newCell->packCheckCell = [packCheckCell retain];
	
	return newCell;
}

- (void)dealloc
{
	[packCheckCell release]; packCheckCell = nil;
	[super dealloc];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	//We have to work by name here since [self objectValue] gives a different object every time
	AIEmoticonPack *pack = [(AIEmoticonsPlugin *)plugin emoticonPackWithName:[[self objectValue] name]];
		
    NSEnumerator    *enumerator;
    AIEmoticon      *emoticon;
    NSColor         *textColor;
    int             x;

	//Indent
    cellFrame.origin.x += EMOTICON_LEFT_MARGIN;

	//Draw the checkbox
	NSSize  checkSize = [packCheckCell cellSize];
	float   checkHeight = checkSize.height;
	NSRect  checkFrame = NSMakeRect(cellFrame.origin.x,
									cellFrame.origin.y,
									checkSize.width,
									checkHeight);

	[packCheckCell setState:[pack isEnabled]];
	[packCheckCell drawWithFrame:checkFrame inView:controlView];
    
    //Determine the correct text color
    if([self isHighlighted]){
        textColor = [NSColor alternateSelectedControlTextColor];
    }else{
        textColor = [NSColor controlTextColor];
    }
    
    //Display the emoticon pack name starting right above the check
    NSDictionary    *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:12], NSFontAttributeName, 
        textColor, NSForegroundColorAttributeName, nil];
    [[pack name] drawAtPoint:NSMakePoint(cellFrame.origin.x + [packCheckCell cellSize].width + EMOTICON_NAME_SPACING,
										 cellFrame.origin.y) 
			  withAttributes:attributes];
	
    //Display a few preview emoticons
    x = cellFrame.origin.x + EMOTICON_ICON_INDENT;
    enumerator = [[pack emoticons] objectEnumerator];
    while((x < cellFrame.size.width - EMOTICON_RIGHT_MARGIN) && (emoticon = [enumerator nextObject])){
        NSImage *image = [emoticon image];
        NSSize  imageSize = [image size];
        NSRect  destRect;
        
        //Scale the emoticon, preserving its proportions.
        if(imageSize.width > EMOTICON_MAX_SIZE){
            destRect.size.width = EMOTICON_MAX_SIZE;
            destRect.size.height = imageSize.height * (EMOTICON_MAX_SIZE / imageSize.width);
        }else if(imageSize.height > EMOTICON_MAX_SIZE){
            destRect.size.width = imageSize.width * (EMOTICON_MAX_SIZE / imageSize.height);
            destRect.size.height = EMOTICON_MAX_SIZE;
        }else{
            destRect.size.width = imageSize.width;
            destRect.size.height = imageSize.height;            
        }
        
        //Position it
        destRect.origin.x = cellFrame.origin.x + x;
        destRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - destRect.size.height) - EMOTICON_BOTTOM_MARGIN;
        
        //If there is enough room, draw the image
        if((destRect.origin.x + destRect.size.width) < (cellFrame.size.width/*-cellFrame.origin.x*/)){
            BOOL    wasFlipped = [image isFlipped];
            
            if(!wasFlipped) [image setFlipped:YES]; //Temporarily flip the image so it appears correct in our flipped view
            [image drawInRect:destRect
                    fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
                    operation:NSCompositeSourceOver
                    fraction:1.0];
            if(!wasFlipped) [image setFlipped:NO];
        }

        //Move over for the next emoticon, leaving some space
		float desiredIncrease = destRect.size.width + EMOTICON_SPACING;
		if (distanceBetweenEmoticons < desiredIncrease)
			distanceBetweenEmoticons = desiredIncrease;
        x += distanceBetweenEmoticons;
    }
}

- (BOOL)trackMouse:(NSEvent*)theEvent inRect:(NSRect)cellFrame ofView:(NSView*)controlView untilMouseUp:(BOOL)untilMouseUp
{
	//Draw the checkbox
	NSSize		checkSize = [packCheckCell cellSize];
	float		checkHeight = checkSize.height;
	NSRect		checkFrame = NSMakeRect(cellFrame.origin.x + EMOTICON_LEFT_MARGIN,
										cellFrame.origin.y,
										checkSize.width,
										checkHeight);
	
	NSPoint		locationInCell;
	BOOL		result = NO;
	
	locationInCell = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
	
	//If the trackMouse: event is inside our checkFrame, pass the necessary calls to packCheckCell
	if(NSPointInRect(locationInCell, checkFrame)) {
		[controlView displayIfNeeded]; //Force all existing displays to occur, otherwise the other cells may try and
									   //draw while we have higlighting on (And draw incorrectly).
		[packCheckCell setHighlighted:YES];
		result = [packCheckCell trackMouse:theEvent inRect:checkFrame ofView:controlView
							  untilMouseUp:untilMouseUp];
		[packCheckCell setHighlighted:NO];
		
		//We have to work by name here since [self objectValue] gives a different object every time
		AIEmoticonPack *pack = [(AIEmoticonsPlugin *)plugin emoticonPackWithName:[[self objectValue] name]];
		[(AIEmoticonsPlugin *)plugin setEmoticonPack:pack enabled:![pack isEnabled]];
		
	} else {
		
		result = [super trackMouse:theEvent inRect:cellFrame ofView:controlView
					  untilMouseUp:untilMouseUp];
	}
	return result;
}

- (BOOL)drawsGradientHighlight
{
	return YES;
}

@end
