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

#define BACK_CELL_LEFT_INDENT	-1
#define BACK_CELL_RIGHT_INDENT	3
#define LABEL_SIDE_PAD		0

@interface AIMessageTabViewItem (PRIVATE)
- (id)initWithMessageView:(AIMessageViewController *)inMessageView owner:(id)inOwner;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect;
- (NSSize)sizeOfLabel:(BOOL)computeMin;
- (NSAttributedString *)attributedLabelStringWithColor:(NSColor *)textColor;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)_observeListObjectAttributes:(AIListObject *)inListObject;
- (void)chatStatusChanged:(NSNotification *)notification;
@end

@implementation AIMessageTabViewItem

//
+ (AIMessageTabViewItem *)messageTabWithView:(AIMessageViewController *)inMessageView owner:(id)inOwner
{
    return([[[self alloc] initWithMessageView:inMessageView owner:inOwner] autorelease]);
}

//init
- (id)initWithMessageView:(AIMessageViewController *)inMessageView owner:(id)inOwner
{
    [super initWithIdentifier:nil];

    messageView = [inMessageView retain];
    owner = [inOwner retain];
    color = nil;

    //Configure ourself for the message view
    [messageView setDelegate:self];
    [self messageViewController:messageView chatChangedTo:[messageView chat]];

    //Set our contents
    [self setView:[messageView view]];
    
    return(self);
}

//
- (void)dealloc
{
    [messageView release];
    [[owner notificationCenter] removeObserver:self];
    [owner release];
    
    [super dealloc];
}

//Access to our message view controller
- (AIMessageViewController *)messageViewController
{
    return(messageView);
}

//Our tab tinting color
- (void)setColor:(NSColor *)inColor
{
    if(color != inColor){
        [color release];
        color = [inColor retain];
    }
}
- (NSColor *)color{
    return(color);
}

//Message View Delegate ----------------------------------------------------------------------
- (void)messageViewController:(AIMessageViewController *)inMessageView chatChangedTo:(AIChat *)chat
{
    //Observe the chat status
    [[owner notificationCenter] removeObserver:self name:Content_ChatStatusChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(chatStatusChanged:) name:Content_ChatStatusChanged object:chat];
    [self chatStatusChanged:nil];

    //Observe the chat's participating list objects
    [[owner notificationCenter] removeObserver:self name:Content_ChatParticipatingListObjectsChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(chatParticipatingListObjectsChanged:) name:Content_ChatParticipatingListObjectsChanged object:chat];
    [self _observeListObjectAttributes:[chat listObject]];

}

//
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
    [self _observeListObjectAttributes:[[notification object] listObject]];
}

//
- (void)_observeListObjectAttributes:(AIListObject *)inListObject
{    
    //Observe it's primary list object's status
    [[owner notificationCenter] removeObserver:self name:ListObject_AttributesChanged object:nil];
    if(inListObject){
        [[owner notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) name:ListObject_AttributesChanged object:inListObject];
    }
}

//
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*keys = [[notification userInfo] objectForKey:@"Keys"];
    
    //If the display name changed, we resize the tabs
    if(notification == nil || [keys containsObject:@"DisplayName"]){
        //This should really be looked at and possibly a better method found.  This works and causes an automatic update to each open tab.  But it feels like a hack.  There is probably a more elegant method.  Something like [[[self tabView] delegate] redraw];  I guess that's what this causes to happen, but the indirectness bugs me. - obviously not the best solution, but good enough for now.
        [[[self tabView] delegate] tabViewDidChangeNumberOfTabViewItems:[self tabView]];
    }    
}

//
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*listObject = [notification object];
    NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];

    //We only need to redraw if the text color has changed
    if([keys containsObject:@"Tab Color"] || [keys containsObject:@"Text Color"] || [keys containsObject:@"Label Color"]){
        //This should really be optimized and cleaned up.  Right now we're assuming the tab view's delegate is our custom tabs, and telling them to display - obviously not the best solution, but good enough for now.
        [self setColor:[[listObject displayArrayForKey:@"Tab Color"] averageColor]];
        [[[self tabView] delegate] setNeedsDisplay:YES];
    }

    //If the list object's display name changed, we resize the tabs
    if([keys containsObject:@"Display Name"]){
        //This should really be looked at and possibly a better method found.  This works and causes an automatic update to each open tab.  But it feels like a hack.  There is probably a more elegant method.  Something like [[[self tabView] delegate] redraw];  I guess that's what this causes to happen, but the indirectness bugs me. - obviously not the best solution, but good enough for now.
        [[[self tabView] delegate] tabViewDidChangeNumberOfTabViewItems:[self tabView]];
    }
}


//Interface Container ----------------------------------------------------------------------
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

//Close this container
- (void)close:(id)sender
{
    [[self tabView] removeTabViewItem:self];
}



//Tab view item  ----------------------------------------------------------------------
//Called when our tab is selected
- (void)tabViewItemWasSelected
{
    //Ensure our entry view is first responder
    [messageView makeTextEntryViewFirstResponder];
}

//Close our tab
- (BOOL)tabShouldClose:(id)sender
{
    //Close down our message view
    [messageView closeMessageView];

    return(YES);
}

//Drawing
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect
{
    AIListObject		*listObject = [[messageView chat] listObject];
    NSColor			*backgroundColor = nil;
    BOOL 			selected;

    //
    selected = ([[self tabView] selectedTabViewItem] == self);
    backgroundColor = [[listObject displayArrayForKey:@"Label Color"] averageColor];

    if(selected){
        labelRect.origin.y += 1;
    }

    NSRect textRect = labelRect;

    textRect.size.width -= LABEL_SIDE_PAD*2;
    textRect.origin.x += LABEL_SIDE_PAD;
    
    //Background
    if(backgroundColor && !selected){
        backgroundColor = [backgroundColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        backgroundColor = [NSColor colorWithCalibratedHue:[backgroundColor hueComponent]
                             saturation:[backgroundColor saturationComponent]
                             brightness:([backgroundColor brightnessComponent] - 0.2)
                                                    alpha:0.8];
            
        int 		innerLeft, innerRight, innerTop, innerBottom;
        float 		centerY, circleRadius;
        NSBezierPath	*pillPath;

        //Calculate some points
        innerLeft = labelRect.origin.x + BACK_CELL_LEFT_INDENT;
        innerRight = labelRect.origin.x + labelRect.size.width - BACK_CELL_RIGHT_INDENT;
        innerTop = labelRect.origin.y;
        innerBottom = labelRect.origin.y + labelRect.size.height;
        circleRadius = -(innerTop - innerBottom) / 2.0;
        centerY = (innerTop + innerBottom) / 2.0;

        //Create the circle path
        pillPath = [NSBezierPath bezierPath];
        [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
        [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:270 endAngle:90 clockwise:NO];
        [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:90 endAngle:270 clockwise:NO];

        //Draw
        [backgroundColor set];
        [pillPath fill];

        NSColor *textColor = [[listObject displayArrayForKey:@"Text Color"] averageColor];

        if([textColor colorIsDark]){
            [[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.4]]
                                  drawInRect:NSOffsetRect(textRect, 0, -1)];
        }else{
            [[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.4]]
                                  drawInRect:NSOffsetRect(textRect, 0, -1)];
        }
        [[self attributedLabelStringWithColor:[textColor darkenBy:0.1]]
                                  drawInRect:textRect];

    }else{
        NSRect textRect = labelRect;

        textRect.size.width -= LABEL_SIDE_PAD*2;
        textRect.origin.x += LABEL_SIDE_PAD;

        //Draw name
        [[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.4]]
                                drawInRect:NSOffsetRect(textRect, 0, -1)];
        [[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:0.16 alpha:1.0]]
                                drawInRect:textRect];
        
    }
/*
    //Draw name
    [[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.4]]
                                    drawInRect:NSOffsetRect(labelRect, 0, -1)];
    [[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:0.16 alpha:1.0]]
                                    drawInRect:labelRect];
*/
}

- (NSSize)sizeOfLabel:(BOOL)computeMin
{
    NSSize		size = [[self attributedLabelStringWithColor:[NSColor blackColor]] size]; //Name width

    //Padding
    size.width += LABEL_SIDE_PAD * 2;

    //Make sure we return an even integer width
    if(size.width != (int)size.width){
        size.width = (int)size.width + 1;
    }

    return(size);
}

//
- (NSString *)labelString
{
    AIChat		*chat = [messageView chat];
    NSString		*displayName;

    if(displayName = [[chat statusDictionary] objectForKey:@"DisplayName"]){
        return(displayName);
    }else{
        return([[chat listObject] displayName]);
    }
}

//
- (NSAttributedString *)attributedLabelStringWithColor:(NSColor *)textColor
{
    NSFont			*font = [NSFont boldSystemFontOfSize:11];
    NSAttributedString		*displayName;
    NSMutableParagraphStyle	*paragraphStyle;
    
    //Paragraph Style (Turn off clipping by word)
    paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByClipping];

    //Name
    displayName = [[NSAttributedString alloc] initWithString:[self labelString] attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]];

    return([displayName autorelease]);
}


@end
