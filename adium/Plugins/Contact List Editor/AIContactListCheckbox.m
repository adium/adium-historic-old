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

#import "AIContactListCheckbox.h"
#import "AIImageUtilities.h"

@implementation AIContactListCheckbox

- (id)init
{
    [super init];

    //pre-load the images
    miniCheck_Enabled = [[AIImageUtilities imageNamed:@"miniCheck_Enabled" forClass:[self class]] retain];
    miniCheck_Disabled = [[AIImageUtilities imageNamed:@"miniCheck_Disabled" forClass:[self class]] retain];
    miniCheck_Enabled_Press = [[AIImageUtilities imageNamed:@"miniCheck_Enabled_Press" forClass:[self class]] retain];
    miniCheck_Selected = [[AIImageUtilities imageNamed:@"miniCheck_Selected" forClass:[self class]] retain];
    miniCheck_Selected_Press = [[AIImageUtilities imageNamed:@"miniCheck_Selected_Press" forClass:[self class]] retain];
    miniCheck_Mixed = [[AIImageUtilities imageNamed:@"miniCheck_Mixed" forClass:[self class]] retain];
    miniCheck_Mixed_Press = [[AIImageUtilities imageNamed:@"miniCheck_Mixed_Press" forClass:[self class]] retain];

    //Config ourselves a bit
    [self setBordered:NO];
    [self setBezeled:NO];
    [self setEnabled:YES];
    
    return(self);
}

- (id)copyWithZone:(NSZone *)zone
{
    AIContactListCheckbox	*new = [super copyWithZone:zone];

    new->miniCheck_Disabled = [miniCheck_Disabled retain];
    new->miniCheck_Enabled = [miniCheck_Enabled retain];
    new->miniCheck_Enabled_Press = [miniCheck_Enabled_Press retain];
    new->miniCheck_Selected = [miniCheck_Selected retain];
    new->miniCheck_Selected_Press = [miniCheck_Selected_Press retain];
    new->miniCheck_Mixed = [miniCheck_Mixed retain];
    new->miniCheck_Mixed_Press = [miniCheck_Mixed_Press retain];

    new->state = state;

    return(new);
}

- (void)dealloc
{
    [miniCheck_Disabled release];
    [miniCheck_Enabled release];
    [miniCheck_Enabled_Press release];
    [miniCheck_Selected release];
    [miniCheck_Selected_Press release];
    [miniCheck_Mixed release];
    [miniCheck_Mixed_Press release];

    [super dealloc];
}

- (void)setState:(int)inState
{
    state = inState;
}

- (int)state
{
    return(state);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
/*{
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView*/
{
    NSImage	*image = nil;
    BOOL	enabled, highlighted;
    NSSize	imageSize;

    //Erease the rect
    [[NSColor clearColor] set];
    [NSBezierPath fillRect:cellFrame];

    enabled = [self isEnabled];
    highlighted = [self isHighlighted];

    //Draw the correct mini-check image
    if(!enabled){
        image = miniCheck_Disabled;
    }else if(state == NSOffState){
        if(!highlighted){
            image = miniCheck_Enabled;
        }else{
            image = miniCheck_Enabled_Press;
        }
    }else if(state == NSOnState){
        if(!highlighted){
            image = miniCheck_Selected;
        }else{
            image = miniCheck_Selected_Press;
        }
    }else{ //if(state == NSMixedState){
        if(!highlighted){
            image = miniCheck_Mixed;
        }else{
            image = miniCheck_Mixed_Press;
        }
    }

    //Draw the image centered
    imageSize = [image size];
    cellFrame.origin.x += (cellFrame.size.width - imageSize.width) / 2.0;
    cellFrame.origin.y -= (cellFrame.size.height - imageSize.height) / 2.0;
    
    [image compositeToPoint:NSMakePoint(cellFrame.origin.x ,cellFrame.origin.y + cellFrame.size.height) operation:NSCompositeSourceOver];
}

@end




