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

#define BACK_CELL_LEFT_INDENT	-1
#define BACK_CELL_RIGHT_INDENT	3
#define LABEL_SIDE_PAD		0

@interface AIMessageTabViewItem (PRIVATE)
- (id)initWithMessageView:(AIMessageViewController *)inMessageView;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect;
- (NSSize)sizeOfLabel:(BOOL)computeMin;
- (NSAttributedString *)attributedLabelStringWithColor:(NSColor *)textColor;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)chatStatusChanged:(NSNotification *)notification;
@end

@implementation AIMessageTabViewItem

//
+ (AIMessageTabViewItem *)messageTabWithView:(AIMessageViewController *)inMessageView
{
    return([[[self alloc] initWithMessageView:inMessageView] autorelease]);
}

//init
- (id)initWithMessageView:(AIMessageViewController *)inMessageView
{
    [super initWithIdentifier:nil];

    messageView = [inMessageView retain];
    adium = [AIObject sharedAdiumInstance];

    //Configure ourself for the message view
    [messageView setDelegate:self];
    [[adium notificationCenter] addObserver:self selector:@selector(chatStatusChanged:)
									   name:Content_ChatStatusChanged
									 object:[messageView chat]];
    [[adium notificationCenter] addObserver:self selector:@selector(chatParticipatingListObjectsChanged:)
									   name:Content_ChatParticipatingListObjectsChanged
									 object:[messageView chat]];
    [self chatStatusChanged:nil];
    [self chatParticipatingListObjectsChanged:nil];

    //Set our contents
    [self setView:[messageView view]];
    
    return(self);
}

//
- (void)dealloc
{
    [messageView release];
    [[adium notificationCenter] removeObserver:self];

    [super dealloc];
}

//Access to our message view controller
- (AIMessageViewController *)messageViewController
{
    return(messageView);
}

//Message View Delegate ----------------------------------------------------------------------
//
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
    //Observe it's primary list object's status
    [[adium notificationCenter] removeObserver:self name:ListObject_AttributesChanged object:nil];
	if([messageView listObject]){
		[[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:)
										   name:ListObject_AttributesChanged
										 object:[messageView listObject]];
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
    //AIListObject	*listObject = [notification object];
    NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];

    //We only need to redraw if the text color has changed
    if(keys == nil || /*[keys containsObject:@"Tab Color"] ||*/ [keys containsObject:@"Tab Text Color"]){
        //This should really be optimized and cleaned up.  Right now we're assuming the tab view's delegate is our custom tabs, and telling them to display - obviously not the best solution, but good enough for now.
        //[self setColor:[[listObject displayArrayForKey:@"Tab Color"] averageColor]];

        [[[self tabView] delegate] redisplayTabForTabViewItem:self];
    }

    //If the list object's display name changed, we resize the tabs
    if(keys == nil || [keys containsObject:@"Display Name"]){
        //This should really be looked at and possibly a better method found.  This works and causes an automatic update to each open tab.  But it feels like a hack.  There is probably a more elegant method.  Something like [[[self tabView] delegate] redraw];  I guess that's what this causes to happen, but the indirectness bugs me. - obviously not the best solution, but good enough for now.
        [[[self tabView] delegate] resizeTabs];
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

//Drawing
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect
{
    BOOL		texturedWindow = [[[self tabView] window] isTextured];
    AIListObject	*listObject = [[messageView chat] listObject];
    NSColor		*textColor = nil;
    BOOL		selected;
    
    //Disable sub-pixel rendering.  It looks horrible with embossed text
    CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], 0);

    //
    selected = ([[self tabView] selectedTabViewItem] == self);
    textColor = [[listObject displayArrayForKey:@"Tab Text Color"] objectValue];
    if(!textColor) textColor = (texturedWindow ? [NSColor colorWithCalibratedWhite:0.16 alpha:1.0] : [NSColor controlTextColor]);
	
    //Emboss the name (Textured window only)
    if(texturedWindow){
		if([textColor colorIsDark]){
			[[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.4]]
                                    drawInRect:NSOffsetRect(labelRect, 0, -1)];
		}else{
			[[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.4]]
                                    drawInRect:NSOffsetRect(labelRect, 0, -1)];
		}
    }
	
    [[self attributedLabelStringWithColor:textColor] drawInRect:labelRect];
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
    AIChat			*chat = [messageView chat];
    NSString		*displayName;
	
    if(displayName = [[chat statusDictionary] objectForKey:@"DisplayName"]){
        return(displayName);
    }else{
		AIListObject *listObject = [chat listObject];
        return(listObject ? [listObject displayName] : [chat name]);
    }
}

//
- (NSAttributedString *)attributedLabelStringWithColor:(NSColor *)textColor
{
    BOOL					texturedWindow = [[[self tabView] window] isTextured];
    NSFont					*font = (texturedWindow ? [NSFont boldSystemFontOfSize:11] : [NSFont systemFontOfSize:11]);
    NSAttributedString      *displayName;
    NSParagraphStyle	    *paragraphStyle;

    //Paragraph Style (Turn off clipping by word)
    paragraphStyle = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment lineBreakMode:NSLineBreakByClipping];

    //Name
    displayName = [[NSAttributedString alloc] initWithString:[self labelString] attributes:
	[NSDictionary dictionaryWithObjectsAndKeys:
	    font, NSFontAttributeName,
	    paragraphStyle, NSParagraphStyleAttributeName,
	    textColor, NSForegroundColorAttributeName,
	    nil]];

    return([displayName autorelease]);
}


@end
