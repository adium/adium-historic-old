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

#import <Adium/Adium.h>
#import "AISCLViewPlugin.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AIAdium.h"
#import "AICLPreferences.h"

@interface AISCLViewPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)itemDidExpand:(NSNotification *)notification;
- (void)itemDidCollapse:(NSNotification *)notification;
- (void)expandCollapseGroup:(AIContactGroup *)inGroup subgroups:(BOOL)subgroups outlineView:(NSOutlineView *)inView;
@end

@implementation AISCLViewPlugin

- (void)installPlugin
{
    SCLViewArray = [[NSMutableArray alloc] init];

    //Register ourself as an available contact list view
    [[owner interfaceController] registerContactListViewController: self];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];

    //Install the preference view
    preferences = [[AICLPreferences contactListPreferencesWithOwner:owner] retain];
}

- (void)uninstallPlugin
{
    //[[owner interfaceController] unregisterContactListViewController: self];
}

- (void)dealloc
{
    [SCLViewArray release];
    [contactList release];

    [super dealloc];
}

//Return our view
- (NSView *)contactListView
{
    AISCLOutlineView	*SCLView;

    //Create the view
    SCLView = [[AISCLOutlineView alloc] init];
    [SCLViewArray addObject:SCLView];

    //Apply the preferences to the view
    [self preferencesChanged:nil];

    //Install the necessary observers (general)
    if([SCLViewArray count] == 1){ //If this is the first view opened
        [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactListChanged:) name:Contact_ListChanged object:nil];
        [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactObjectChanged:) name:Contact_ObjectChanged object:nil];
        [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactAttributesChanged:) name:Contact_AttributesChanged object:nil];
        [[[owner preferenceController] preferenceNotificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    }

    //View specific
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:SCLView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:SCLView];
    [SCLView setTarget:self];
    [SCLView setDataSource:self];
    [SCLView setDelegate:self];
    [SCLView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];
    [self expandCollapseGroup:contactList subgroups:YES outlineView:SCLView]; //Correctly expand/collapse groups
    
    //Fetch and retain the contact list
    contactList = [[[owner contactController] contactList] retain];

    return([SCLView autorelease]);
}

- (void)closeContactListView:(NSView *)inView
{    
    if([inView isKindOfClass:[AISCLOutlineView class]]){
        AISCLOutlineView	*view = (AISCLOutlineView *)inView;

        //Remove observers (general)
        if([SCLViewArray count] == 1){ //If this is the last view closed
            [[[owner contactController] contactNotificationCenter] removeObserver:self name:Contact_ListChanged object:nil];
            [[[owner contactController] contactNotificationCenter] removeObserver:self name:Contact_ObjectChanged object:nil];
            [[[owner contactController] contactNotificationCenter] removeObserver:self name:Contact_AttributesChanged object:nil];
            [[[owner preferenceController] preferenceNotificationCenter] removeObserver:self name:Preference_GroupChanged object:nil];
        }
    
        //View specific
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewItemDidExpandNotification object:view];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewItemDidCollapseNotification object:view];
        
        //Close down and release the view
        [view setTarget:nil];
        [view setDataSource:nil];
        [view setDelegate:nil];
        [SCLViewArray removeObject:view];
    }
}


//Notifications
//Reload the contact list
- (void)contactListChanged:(NSNotification *)notification
{
    NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
    AISCLOutlineView	*SCLView;

    //Fetch the new contact list
    [contactList release]; contactList = [[[owner contactController] contactList] retain];

    //Redisplay
    while((SCLView = [enumerator nextObject])){
        [SCLView reloadData];
        [self expandCollapseGroup:contactList subgroups:YES outlineView:SCLView]; //Correctly expand/collapse groups
    }
}

//Reload the contact list (if updates aren't delayed)
- (void)contactObjectChanged:(NSNotification *)notification
{
    if(![[owner contactController] contactListUpdatesDelayed]){
        NSEnumerator		*enumerator = [SCLViewArray objectEnumerator];
        AISCLOutlineView	*SCLView;
        BOOL			isGroup = [[notification object] isKindOfClass:[AIContactGroup class]];
            
        while((SCLView = [enumerator nextObject])){
            [SCLView reloadData];

            if(isGroup){ //Correctly expand/collapse the group
                [self expandCollapseGroup:(AIContactGroup *)[notification object] subgroups:YES outlineView:SCLView]; 
            }
        }
    }
}

//Redisplay the modified object
- (void)contactAttributesChanged:(NSNotification *)notification
{
    NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
    AISCLOutlineView	*SCLView;

    while((SCLView = [enumerator nextObject])){
        [SCLView setNeedsDisplay:YES];
    }
}

//A contact list preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
        NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
        AISCLOutlineView	*SCLView;
    
        while((SCLView = [enumerator nextObject])){
            NSFont	*font = [[prefDict objectForKey:KEY_SCL_FONT] representedFont];
            float	alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
            NSColor	*backgroundColor = [[prefDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColorWithAlpha:alpha];
            NSColor	*gridColor = [[prefDict objectForKey:KEY_SCL_GRID_COLOR] representedColorWithAlpha:alpha];
            BOOL	alternatingGrid = [[prefDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue];
            
            //Display
            [SCLView setFont:font];
            [SCLView setRowHeight:[font defaultLineHeightForFont]];
            [SCLView setBackgroundColor:backgroundColor];
            
            //Grid
            [SCLView setDrawsAlternatingRows:alternatingGrid];
            [SCLView setAlternatingRowColor:gridColor];
    
            /*
             For this view to be transparent, it's containing window must be set as non-opaque.  It would make sense to use: [[SCLView window] setOpaque:(alpha == 100.0)];

             However, setting a window to opaque causes it's contents to be shadowed.  It is a pain (and a major speed hit) to maintain shadows beneath the contact list text.  A little trick to prevent the window manager from shadowing the window content is to set the window itself as non-opaque.  The contents of a window that is non-opaque will not cast a shadow.  Setting the window's alpha value to 0.9999999 removes the shadowing without giving the slightest appearance of opacity to the window titlebar and widgets.
             */
            [[SCLView window] setAlphaValue:(alpha == 100.0 ? 1.0 : 0.9999999)];

        }
    }
}

//Expand & collapse a group
- (void)itemDidExpand:(NSNotification *)notification
{
    [[[notification userInfo] objectForKey:@"NSObject"] setExpanded:YES];
}
- (void)itemDidCollapse:(NSNotification *)notification
{
    [[[notification userInfo] objectForKey:@"NSObject"] setExpanded:NO];
}
//    [self desiresNewSize];


//Double click in outline view
- (IBAction)performDefaultActionOnSelectedContact:(id)sender
{
    AIContactObject	*selectedObject;

    selectedObject = [sender itemAtRow:[sender selectedRow]];

    if([selectedObject isKindOfClass:[AIContactGroup class]]){
        //Expand or collapse the group
        if([sender isItemExpanded:selectedObject]){
            [sender collapseItem:selectedObject];
        }else{
            [sender expandItem:selectedObject];
        }
    
    }else{
        NSDictionary	*notificationDict;

        //Open a new message with the contact
        notificationDict = [NSDictionary dictionaryWithObjectsAndKeys:selectedObject, @"To", nil];
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:Interface_InitiateMessage object:nil userInfo:notificationDict];
    }
}

// Outline View data source methods
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([contactList sortedObjectAtIndex:index]);
    }else{
        return([item sortedObjectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIContactGroup class]]){
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
        return([contactList sortedCount]);
    }else{
        return([item sortedCount]);
    }
}

// outlineView:willDisplayCell: The outline view is about to tell one of our cells to draw
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    //Before one of our cells gets told to draw, we need to make sure it knows what contact it's drawing for.
    if([cell isKindOfClass:[AISCLCell class]]){
        [(AISCLCell *)cell setContact:item];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return(@"");
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    AIContactObject	*selectedObject = nil;
    NSOutlineView	*outlineView = [notification object];
    int			selectedRow;

    //Get the selected object
    selectedRow = [outlineView selectedRow];
    if(selectedRow >= 0 && selectedRow < [outlineView numberOfRows]){    
        selectedObject = [outlineView itemAtRow:selectedRow];
    }

    //Post a 'contact list selection changed' notification on the interface center
    if(selectedObject){
        NSDictionary	*notificationDict = [NSDictionary dictionaryWithObjectsAndKeys:selectedObject, @"Object", nil];
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:Interface_ContactSelectionChanged object:outlineView userInfo:notificationDict];
    
    }else{
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:Interface_ContactSelectionChanged object:outlineView userInfo:nil];
    
    }

}

//Correctly sets the contact groups as expanded or collapsed, depending on their saved state
- (void)expandCollapseGroup:(AIContactGroup *)inGroup subgroups:(BOOL)subgroups outlineView:(NSOutlineView *)inView
{
    NSEnumerator	*enumerator = [inGroup objectEnumerator];
    AIContactObject	*object;

    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIContactGroup class]]){
            //Correctly expand/collapse the group
            if([(AIContactGroup *)object isExpanded]){
                [inView expandItem:object];
            }else{
                [inView collapseItem:object];
            }

            //Expand/collapse any subgroups
            if(subgroups){
                [self expandCollapseGroup:(AIContactGroup *)object subgroups:YES outlineView:inView];
            }
        }
    }
}


@end





