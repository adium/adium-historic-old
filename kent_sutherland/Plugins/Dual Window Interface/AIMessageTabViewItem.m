/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import <AIUtilities/AICustomTabsView.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

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
    return [[[self alloc] initWithMessageView:inMessageView] autorelease];
}

//init
- (id)initWithMessageView:(AIMessageViewController *)inMessageViewController
{
	if ( (self = [super initWithIdentifier:nil]) ) {
		messageViewController = [inMessageViewController retain];
		adium = [AIObject sharedAdiumInstance];
		container = nil;

		//Configure ourself for the message view
		[[adium notificationCenter] addObserver:self selector:@selector(chatStatusChanged:)
										   name:Chat_StatusChanged
										 object:[messageViewController chat]];
		[[adium notificationCenter] addObserver:self selector:@selector(chatAttributesChanged:)
										   name:Chat_AttributesChanged
										 object:[messageViewController chat]];	
		[[adium notificationCenter] addObserver:self selector:@selector(chatParticipatingListObjectsChanged:)
										   name:Chat_ParticipatingListObjectsChanged
										 object:[messageViewController chat]];
		[self chatStatusChanged:nil];
		[self chatParticipatingListObjectsChanged:nil];
		
		//Set our contents
		[self setView:[messageViewController view]];
		
		controller = [[NSObjectController alloc] initWithContent:self];
		[self setIdentifier:controller];
	}
    return self;
}

//
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];

	[tabViewItemImage release]; tabViewItemImage = nil;

    [messageViewController release]; messageViewController = nil;
	[container release]; container = nil;
	
	[controller release]; controller = nil;

    [super dealloc];
}

//Access to our message view controller
- (AIMessageViewController *)messageViewController
{
    return messageViewController;
}

//Our chat
- (AIChat *)chat
{
	return [messageViewController chat];
}

//Our containing window
- (void)setContainer:(AIMessageWindowController *)inContainer{
	if (inContainer != container) {
		[messageViewController messageViewWillLeaveWindow:[container window]];

		[container release];
		container = [inContainer retain];

		[messageViewController messageViewAddedToWindow:[container window]];
	}
}

- (AIMessageWindowController *)container{
	return container;
}

- (NSObjectController *)controller
{
	return controller;
}

//Message View Delegate ----------------------------------------------------------------------
#pragma mark Message View Delegate

/*
 * @brief The list objects participating in our chat changed
 */
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
	AIListObject	*listObject;

	//Remove the old observer
    [[adium notificationCenter] removeObserver:self name:ListObject_AttributesChanged object:nil];

	//If there is a single list object for this chat, observe its attribute changes
	if ((listObject = [messageViewController listObject])) {
		[[adium notificationCenter] addObserver:self
									   selector:@selector(listObjectAttributesChanged:)
										   name:ListObject_AttributesChanged
										 object:nil];
		
	}
}

//
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*keys = [[notification userInfo] objectForKey:@"Keys"];

    //If the display name changed, we resize the tabs
    if (notification == nil || [keys containsObject:@"DisplayName"]) {
		id delegate = [[self tabView] delegate];
		[delegate resizeTabForTabViewItem:self];
		
        /* This should really be looked at and possibly a better method found.
		 * This works and causes an automatic update to each open tab.  But it feels like a hack.
		 * There is probably a more elegant method.  Something like [[[self tabView] delegate] redraw];  
		 * I guess that's what this causes to happen, but the indirectness bugs me. It's obviously not the best solution,
		 * but good enough for now.
		 */
        [delegate tabViewDidChangeNumberOfTabViewItems:[self tabView]];
    }
}

- (void)chatAttributesChanged:(NSNotification *)notification
{
	NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	//Redraw if the icon has changed
	if (keys == nil || [keys containsObject:@"Tab State Icon"]) {
		[[self container] updateIconForTabViewItem:self];
		[controller didChangeValueForKey:@"selection.icon"];
	}
}
//
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	AIListObject *listObject = [notification object];

	if (!listObject || (listObject == [messageViewController listObject])) {
		NSSet		 *keys = [[notification userInfo] objectForKey:@"Keys"];
		
		//Redraw if the icon has changed
		if (!keys || [keys containsObject:@"Tab Status Icon"]) {
			[[self container] updateIconForTabViewItem:self];
			[controller didChangeValueForKey:@"selection.icon"];
		}
		
		//If the list object's display name changed, we resize the tabs
		if (!keys || [keys containsObject:@"Display Name"]) {
			[[[self tabView] delegate] resizeTabForTabViewItem:self];
		}
	}
}

//Interface Container ----------------------------------------------------------------------
#pragma mark Interface Container

//Make this container active
- (void)makeActive:(id)sender
{
    NSTabView	*tabView = [self tabView];
    NSWindow	*window	= [tabView window];

    if ([tabView selectedTabViewItem] != self) {
        [tabView selectTabViewItem:self]; //Select our tab
    }

    if (![window isKeyWindow]) {
        [window makeKeyAndOrderFront:nil]; //Bring our window to the front
    }
}

//Close this container
- (void)close:(id)sender
{
    [[self tabView] removeTabViewItem:self];
}



//Tab View Item  ----------------------------------------------------------------------
#pragma mark Tab View Item

//Called when our tab is selected
- (void)tabViewItemWasSelected
{
    //Ensure our entry view is first responder
    [messageViewController makeTextEntryViewFirstResponder];
}

//
- (NSString *)label
{
	return ([[messageViewController chat] displayName]);
}

//Return the icon to be used for our tabs.  State gets first priority, then status.
- (NSImage *)icon
{
	NSImage *image = [self stateIcon];
	
	//Multi-user chats won't have status icons
	if (!image && ![messageViewController userListVisible]) image = [self statusIcon];

	if (!image) image = [AIStatusIcons statusIconForUnknownStatusWithIconType:AIStatusIconTab direction:AIIconNormal];

	return image;
}

//Status icon is the status of this contact (away, idle, online, stranger)
- (NSImage *)statusIcon
{
	return [[[messageViewController chat] listObject] displayArrayObjectForKey:@"Tab Status Icon"];
}

//State icon is the state of the contact (Typing, unviewed content)
- (NSImage *)stateIcon
{
	return [[messageViewController chat] displayArrayObjectForKey:@"Tab State Icon"];
}

- (NSImage *)image
{
	return tabViewItemImage;
}

@end
