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

#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define LEFT_VIEW_PADDING 	2
#define LEFT_VIEW_HEIGHT 	13
#define LEFT_MARGIN		4

@interface AIMessageTabViewItem (PRIVATE)
- (id)initWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect;
- (NSSize)sizeOfLabel:(BOOL)computeMin;
- (NSAttributedString *)attributedLabelString;
@end

@implementation AIMessageTabViewItem

//
+ (AIMessageTabViewItem *)messageTabViewItemWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner
{
    return([[[self alloc] initWithIdentifier:identifier messageView:inMessageView owner:inOwner] autorelease]);
}

//init
- (id)initWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner
{
    [super initWithIdentifier:identifier];

    messageView = [inMessageView retain];
    owner = [inOwner retain];

    //Observer
    [[owner notificationCenter] addObserver:self selector:@selector(contactAttributesChanged:) name:Contact_AttributesChanged object:nil];
    
    //Set our contents
    [self setView:[messageView view]];
    
    return(self);
}

//
- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self name:Contact_AttributesChanged object:nil];
    [owner release];
    
    [super dealloc];
}

//Redisplay the modified object
- (void)contactAttributesChanged:(NSNotification *)notification
{
    NSArray	*keys = [[notification userInfo] objectForKey:@"Keys"];
    
    //We only need to redraw if the text color has changed
    if([keys containsObject:@"Text Color"] || [keys containsObject:@"Tab Left View"]){
        //This should really be optimized and cleaned up.  Right now we're assuming the tab view's delegate is our custom tabs, and telling them to display - obviously not the best solution, but good enough for now.
        [[[self tabView] delegate] setNeedsDisplay:YES];
    }
}

//Make this container active
- (void)makeActive:(id)sender
{
    NSTabView	*tabView = [self tabView];
    NSWindow	*window	= [tabView window];
    
    if([tabView selectedTabViewItem] != self){
        [tabView selectTabViewItem:self]; //Select our tab
    }

    if(![window isKeyWindow]){
        [window makeKeyAndOrderFront:nil]; //Bring our window to the front        
    }
}

//Called when our tab is selected
- (void)tabViewItemWasSelected
{
    //Ensure our entry view is first responder
    [messageView makeTextEntryViewFirstResponder];
}

//
- (AIMessageViewController *)messageViewController
{
    return(messageView);
}

//Close this container
- (void)close:(id)sender
{
    [[self tabView] removeTabViewItem:self];
}

//Drawing
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect
{
    AIMutableOwnerArray	*leftViewArray;

    //Draw icon
    leftViewArray = [[messageView contact] displayArrayForKey:@"Tab Left View"];

    //If a left view is present
    if(leftViewArray && [leftViewArray count]){
        int			loop;

        //indent into the margin to save space
        labelRect.origin.x -= LEFT_MARGIN;
        labelRect.size.width += LEFT_MARGIN;

        //Draw all icons
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIContactLeftView>	handler = [leftViewArray objectAtIndex:loop];
            NSRect			drawRect = labelRect;

            //Get the icon's dest drawing rect
            drawRect.size.height = LEFT_VIEW_HEIGHT;
            drawRect.size.width = [handler widthForHeight:drawRect.size.height computeMax:NO];

            //Draw the icon
            [handler drawInRect:drawRect];

            //Subtract the drawn area from the rect
            labelRect.origin.x += (drawRect.size.width + LEFT_VIEW_PADDING);
            labelRect.size.width -= (drawRect.size.width + LEFT_VIEW_PADDING);
        }
    }

    //Draw name    
    [[self attributedLabelString] drawInRect:labelRect];
}

- (NSSize)sizeOfLabel:(BOOL)computeMin
{
    AIMutableOwnerArray	*leftViewArray;
    NSSize		size;

    //Name width
    size = [[self attributedLabelString] size];

    //Icon widths
    leftViewArray = [[messageView contact] displayArrayForKey:@"Tab Left View"];
    if(leftViewArray && [leftViewArray count]){ //If a left view is present
        int	loop;

        //indent into the margin to save space
        size.width -= LEFT_MARGIN;

        //Account for the width of each icon
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIContactLeftView>	handler = [leftViewArray objectAtIndex:loop];

            size.width += [handler widthForHeight:LEFT_VIEW_HEIGHT computeMax:NO] + LEFT_VIEW_PADDING;
        }
    }

    //Make sure we return an even integer width
    if(size.width != (int)size.width){
        size.width = (int)size.width + 1;
    }

    return(size);
}

//
- (NSString *)labelString
{
    return([[messageView contact] displayName]);
}

//
- (NSAttributedString *)attributedLabelString
{
    AIListContact	*contact = [messageView contact];
    NSFont		*font = [NSFont systemFontOfSize:11];
    NSAttributedString	*displayName;
    NSColor		*textColor;

    
    //Color
    textColor = [[contact displayArrayForKey:@"Text Color"] averageColor];
    if(!textColor){
        textColor = [NSColor blackColor];
    }

    //Name
    displayName = [[NSAttributedString alloc] initWithString:[contact displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,font,NSFontAttributeName,nil]];

    return([displayName autorelease]);
}

@end
