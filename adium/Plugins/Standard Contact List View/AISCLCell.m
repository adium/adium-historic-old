/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"

@implementation AISCLCell

- (void)setContact:(AIContactObject *)inObject
{
    contactObject = inObject;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSFont	*font = [(AISCLOutlineView *)controlView font];
    
    if([contactObject isKindOfClass:[AIContactHandle class]]){
        NSString		*name;
        NSAttributedString	*displayName;
        NSColor			*textColor;
        AIMutableOwnerArray	*leftViewArray;
        int			loop;

        cellFrame.origin.x -= 6;
        cellFrame.size.width += 6;

        // Icons can be 14 pixels wide, as they grow larger, they stop pushing the text right and instead push left.  Once the left margin is full (14?), they continue to push right again.

        //Left aligned icon
        leftViewArray = [contactObject displayArrayForKey:@"Left View"];
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIHandleLeftView>	handler = [leftViewArray objectAtIndex:loop];
            NSRect			drawRect = cellFrame;
            int				width = [handler widthForHeight:drawRect.size.height];
            int				push;
        
            if(width <= 14){ //Push right (left aligned)
                drawRect.size.width = width; 
                push = width;
                
            }else if(width <= 28){ //Push right 14, then push left (right aligned)
                drawRect.origin.x = (drawRect.origin.x + 14) - width;
                drawRect.size.width = width;
                push = 14;

            }else{ //Push left (left aligned with margin)
                drawRect.origin.x -= 14;
                drawRect.size.width = width;
                push = width - 14;
            }
        
            //Draw the icon
            [handler drawInRect:drawRect];
            
            //Subtract the drawn area from the rect
            cellFrame.origin.x += (push + 2);
            cellFrame.size.width -= (push + 2);
        }

        //Color
        textColor = [[contactObject displayArrayForKey:@"Text Color"] averageColor];
        if(!textColor){
            textColor = [NSColor blackColor];
        }
        
        //Name
        name = [contactObject displayName];
        displayName = [[NSAttributedString alloc] initWithString:name attributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,font,NSFontAttributeName,nil]];

        //Display
        [displayName drawInRect:cellFrame];
        [displayName release];
        
    }else{
        NSAttributedString	*displayName;
        NSString		*name;

        name = [contactObject displayName];
        displayName = [[NSAttributedString alloc] initWithString:name attributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,nil]];

        cellFrame.origin.x += 2;
        cellFrame.size.width -= 2;

        [displayName drawInRect:cellFrame];
        [displayName release];
    }

}

@end
