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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"

#define LEFT_MARGIN		19
//#define LEFT_VIEW_INDENT_SIZE	1.2 //must be close to square then
#define LEFT_VIEW_PADDING	3

@implementation AISCLCell

- (void)setContact:(AIListObject *)inObject
{
    listObject = inObject;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSFont	*font = [(AISCLOutlineView *)controlView font];
    NSColor	*groupColor = [(AISCLOutlineView *)controlView color];
    NSColor	*invertedGroupColor = [(AISCLOutlineView *)controlView invertedColor];

//    if([listObject isKindOfClass:[AIListContact class]]){
        NSString		*name;
        NSAttributedString	*displayName;
        NSColor			*textColor;
        AIMutableOwnerArray	*leftViewArray;
        int			loop;

        //If a left view is present
        leftViewArray = [listObject displayArrayForKey:@"Left View"];
        if(leftViewArray && [leftViewArray count]){
            //Indent into the margin to save space
            cellFrame.origin.x -= LEFT_MARGIN;
            cellFrame.size.width += LEFT_MARGIN;

            //Left aligned icon
            for(loop = 0;loop < [leftViewArray count];loop++){
                id <AIContactLeftView>	handler = [leftViewArray objectAtIndex:loop];
                NSRect			drawRect;
                float			width, maxWidth;
    
                //Calculate the icon size
                maxWidth = [handler widthForHeight:cellFrame.size.height computeMax:YES];
                width = [handler widthForHeight:cellFrame.size.height computeMax:NO];
    
                //Create a destination rect for the icon
                drawRect = cellFrame;
                drawRect.origin.x += (maxWidth - width);
                drawRect.size.width = width;
            
                //Draw the icon
                [handler drawInRect:drawRect];
                
                //Subtract the drawn area from the remaining rect
                cellFrame.origin.x += (maxWidth + LEFT_VIEW_PADDING);
                cellFrame.size.width -= (maxWidth + LEFT_VIEW_PADDING);
                
            }
        }else{
            //If no left views are present, insert padding to move text away from flippy triangle
            cellFrame.origin.x += LEFT_VIEW_PADDING;
            cellFrame.size.width -= LEFT_VIEW_PADDING;

        }
    
        //Color (If this cell is selected, use the inverted color, or white)
        if([self isHighlighted] && [[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView){
            textColor = [[listObject displayArrayForKey:@"Inverted Text Color"] averageColor];
	    if([listObject isKindOfClass:[AIListGroup class]]) textColor = invertedGroupColor;
            if(!textColor) textColor = [NSColor whiteColor];
        }else{ //use the regular color, or black
            textColor = [[listObject displayArrayForKey:@"Text Color"] averageColor];
	    if([listObject isKindOfClass:[AIListGroup class]]) textColor = groupColor;
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
