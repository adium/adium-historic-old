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

#define LEFT_MARGIN		0 //9
#define LEFT_VIEW_INDENT_SIZE	1.2 //must be close to square then
#define LEFT_VIEW_PADDING	3

@implementation AISCLCell

- (void)setContact:(AIListObject *)inObject
{
    listObject = inObject;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSFont	*font = [(AISCLOutlineView *)controlView font];

//    if([listObject isKindOfClass:[AIListContact class]]){
        NSString		*name;
        NSAttributedString	*displayName;
        NSColor			*textColor;
        AIMutableOwnerArray	*leftViewArray;
        int			loop;

        //Indent into the left margin
        cellFrame.origin.x -= LEFT_MARGIN;
        cellFrame.size.width += LEFT_MARGIN;

        // Icons can be 14 pixels wide, as they grow larger, they stop pushing the text right and instead push left.  Once the left margin is full (14?), they continue to push right again.

        //Left aligned icon
        leftViewArray = [listObject displayArrayForKey:@"Left View"];
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIContactLeftView>	handler = [leftViewArray objectAtIndex:loop];
            NSRect			drawRect = cellFrame;
            float			width = [handler widthForHeight:drawRect.size.height];
            float			push;
            float			leftViewIndent = (drawRect.size.height * LEFT_VIEW_INDENT_SIZE);
        
            if(width <= leftViewIndent){ //Right Aligned
                drawRect.origin.x = (drawRect.origin.x + leftViewIndent) - width;
                drawRect.size.width = width;
                push = leftViewIndent;
                
            }else if(width <= (leftViewIndent * 2)){ //Into the margin, right aligned
                drawRect.origin.x = (drawRect.origin.x + leftViewIndent) - width;
                drawRect.size.width = width;
                push = leftViewIndent;

            }else{ //Into the margin, indent text to make space
                drawRect.origin.x -= leftViewIndent;
                drawRect.size.width = width;
                push = width - leftViewIndent;
            }
        
            //Draw the icon
            [handler drawInRect:drawRect];
            
            //Subtract the drawn area from the rect
            cellFrame.origin.x += (push + LEFT_VIEW_PADDING);
            cellFrame.size.width -= (push + LEFT_VIEW_PADDING);
        }

        //Color
        //If this cell is selected, use the inverted color, or white
        if([self isHighlighted] && [[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView){
            textColor = [[listObject displayArrayForKey:@"Inverted Text Color"] averageColor];
            if(!textColor) textColor = [NSColor whiteColor];
        }else{ //use the regular color, or black
            textColor = [[listObject displayArrayForKey:@"Text Color"] averageColor];
            if(!textColor) textColor = [NSColor blackColor];
        }
        
        //Name
        name = [listObject displayName];
        displayName = [[NSAttributedString alloc] initWithString:name attributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,font,NSFontAttributeName,nil]];

        //Display
        cellFrame.origin.y -= 1; //Adjust the strings up 1 pixel
        [displayName drawAtPoint:cellFrame.origin];

        [displayName release];
        
/*    }else{
        NSAttributedString	*displayName;
        NSString		*name;

        name = [listObject displayName];
        displayName = [[NSAttributedString alloc] initWithString:name attributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,nil]];

        cellFrame.origin.x += 2;
        cellFrame.size.width -= 2;

        cellFrame.origin.y -= 1; //Adjust the strings up 1 pixel
        [displayName drawAtPoint:cellFrame.origin];
        [displayName release];
    }*/

}

@end
