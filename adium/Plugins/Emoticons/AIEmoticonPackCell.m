/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@implementation AIEmoticonPackCell

#define EMOTICON_MAX_SIZE           20
#define EMOTICON_SPACING            4
#define EMOTICON_LEFT_MARGIN        4
#define EMOTICON_LEFT_ICON_MARGIN   6
#define EMOTICON_BOTTOM_MARGIN      4
#define EMOTICON_TOP_MARGIN         0

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    AIEmoticonPack  *pack = [self objectValue];
    NSEnumerator    *enumerator;
    AIEmoticon      *emoticon;
    NSColor         *textColor;
    int             x;
    
    //Indent
    cellFrame.origin.x += EMOTICON_LEFT_MARGIN;
    
    //Determine the correct text color
    if([self isHighlighted]){
        textColor = [NSColor alternateSelectedControlTextColor];
    }else{
        textColor = [NSColor controlTextColor];
    }
    
    //Display the emoticon pack name
    NSDictionary    *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:12], NSFontAttributeName, 
        textColor, NSForegroundColorAttributeName, nil];
    [[pack name] drawAtPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y) withAttributes:attributes];

    //Display a few preview emoticons
    x = EMOTICON_LEFT_ICON_MARGIN;
    enumerator = [[pack emoticons] objectEnumerator];
    while(x < cellFrame.size.width && (emoticon = [enumerator nextObject])){
        NSImage *image = [emoticon image];
        NSSize  imageSize = [image size];
        NSRect  destRect;
        
        //Scale the emoticon, preserving it's proportions.
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
        if(x + destRect.size.width < cellFrame.size.width){
            BOOL    wasFlipped = [image isFlipped];
            
            if(!wasFlipped) [image setFlipped:YES]; //Temporarily flip the image so it appears correct in our flipped view
            [image drawInRect:destRect
                    fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
                    operation:NSCompositeSourceOver
                    fraction:1.0];
            if(!wasFlipped) [image setFlipped:NO];
        }

        //Move over for the next emoticon, leaving some space
        x += imageSize.width + EMOTICON_SPACING;
    }
}

- (BOOL)drawsGradientHighlight
{
	return YES;
}

@end
