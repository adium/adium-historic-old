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

#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"

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
- (void)updateTabViewItemImage;
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
	container = nil;

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
	[self updateTabViewItemImage];
	
    //Set our contents
    [self setView:[messageView view]];
    
    return(self);
}

//
- (void)dealloc
{
	[tabViewItemImage release]; tabViewItemImage = nil;
    [messageView release];
    [[adium notificationCenter] removeObserver:self];

    [super dealloc];
}

//Access to our message view controller
- (AIMessageViewController *)messageViewController
{
    return(messageView);
}

//Our chat
- (AIChat *)chat
{
	return([messageView chat]);
}

//Our containing window
- (void)setContainer:(AIMessageWindowController *)inContainer{
	container = inContainer;
}
- (AIMessageWindowController *)container{
	return(container);
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
    NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];

	//Redraw if the icon has changed
	if(keys == nil || [keys containsObject:@"Tab State Icon"] || [keys containsObject:@"Tab Status Icon"]){
		[[[self tabView] delegate] redisplayTabForTabViewItem:self];
		[[self container] updateIconForTabViewItem:self];
	}
	
    //If the list object's display name changed, we resize the tabs
    if(keys == nil || [keys containsObject:@"Display Name"]){
		[[[self tabView] delegate] resizeTabForTabViewItem:self];
    }
	
	if(keys == nil || [keys containsObject:KEY_USER_ICON]){
		[self updateTabViewItemImage];
	}
}

- (void)updateTabViewItemImage
{
	AIListObject	*listObject = [messageView listObject];

	[tabViewItemImage release];
	if (listObject){
		NSImage		*userIcon = [[listObject displayArrayForKey:KEY_USER_ICON] objectValue];
		if (userIcon){
			tabViewItemImage = [[userIcon imageByScalingToSize:NSMakeSize(16,16)] retain];
		}else{
			if ([listObject isKindOfClass:[AIListContact class]]){
				tabViewItemImage = [[[[adium accountController] accountWithObjectID:[(AIListContact *)listObject accountID]] menuImage] retain];
			}
		}
	}else{
		tabViewItemImage = [[[[messageView chat] account] menuImage] retain];
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

//
- (NSString *)label
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

//Return the icon to be used for our tabs.  State gets first priority, then status.
- (NSImage *)icon
{
	NSImage *image = [self stateIcon];
	return(image ? image : [self statusIcon]);
}

//Status icon is the status of this contact (away, idle, online, stranger)
- (NSImage *)statusIcon
{
	return([[[[messageView chat] listObject] displayArrayForKey:@"Tab Status Icon"] objectValue]);
}

//State icon is the state of the contact (Typing, unviewed content)
- (NSImage *)stateIcon
{
	return([[[[messageView chat] listObject] displayArrayForKey:@"Tab State Icon"] objectValue]);
}

- (NSImage *)image
{
	return tabViewItemImage;
}

@end
