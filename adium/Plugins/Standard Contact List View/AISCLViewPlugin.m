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

@end

@implementation AISCLViewPlugin

- (void)installPlugin
{
    SCLViewArray = [[NSMutableArray alloc] init];

    //Register ourself as an available contact list view
    [[owner interfaceController] registerContactListViewController: self];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:GROUP_CONTACT_LIST];

    //Install the preference view
    preferences = [[AICLPreferences contactListPreferencesWithOwner:owner] retain];
}

- (void)dealloc
{
    [SCLViewArray release];
    [contactList release];

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

    //Install the necessary observers
    [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactListChanged:) name:Contact_ListChanged object:nil];
    [[[owner contactController] contactNotificationCenter] addObserver:self selector:@selector(contactChanged:) name:Contact_ObjectChanged object:nil];
    [[[owner preferenceController] preferenceNotificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpandOrCollapse:) name:NSOutlineViewItemDidExpandNotification object:SCLView];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpandOrCollapse:) name:NSOutlineViewItemDidCollapseNotification object:SCLView];
    
    [SCLView setTarget:self];
    [SCLView setDataSource:self];
    [SCLView setDelegate:self];
    [SCLView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];
    
    //Fetch and retain the contact list
    contactList = [[[owner contactController] contactList] retain];

    return([SCLView autorelease]);
}

//Notifications
- (void)contactListChanged:(NSNotification *)notification
{
    NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
    AISCLOutlineView	*SCLView;
    
    while((SCLView = [enumerator nextObject])){
        [SCLView reloadData];
    }
}

- (void)contactChanged:(NSNotification *)notification
{
    if(![[owner contactController] contactListUpdatesDelayed]){
        NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
        AISCLOutlineView	*SCLView;

        while((SCLView = [enumerator nextObject])){
            [SCLView reloadData];
        }
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:GROUP_CONTACT_LIST];
    NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
    AISCLOutlineView	*SCLView;

    while((SCLView = [enumerator nextObject])){
        NSFont	*font = [[prefDict objectForKey:KEY_SCL_FONT] representedFont];
        BOOL	alternatingGrid = [[prefDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue];

        //Font
        [SCLView setFont:font];
        [SCLView setRowHeight:[font defaultLineHeightForFont]];

        //Grid
        [SCLView setDrawsAlternatingRows:alternatingGrid];

    }

    
    
    
    

    
}

/*- (void)prefsChanged: (NSNotification *)notification
{
    NSEnumerator	*enumerator = [SCLViewArray objectEnumerator];
    AISCLOutlineView	*SCLView;

    NSDictionary *dict = [[owner preferenceController] preferencesForGroup: CL_PREFERENCE_GROUP];
    while((SCLView = [enumerator nextObject]))
	{
        NSFont *font = [NSFont fontWithName:[NSString stringWithFormat:@"%@", [[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"FONT"]] size: [[[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"SIZE"] floatValue]]; // iacas - 12/22/2002 - it expects a float, not an int

		NSLog(@"font: %@", [NSFont fontWithName:[NSString stringWithFormat:@"%@", [[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"FONT"]] size: [[[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"SIZE"] floatValue]]);
        
        [SCLView setFont:font];
        [SCLView setRowHeight:[font defaultLineHeightForFont]];
        
        [SCLView setBackgroundColor: [NSColor colorWithCalibratedRed:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"RED"] floatValue]
                                                               green:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"GREEN"] floatValue]
                                                                blue:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"BLUE"] floatValue]
                                                               alpha:[[dict objectForKey: CL_OPACITY] floatValue]]];

        [SCLView setDrawsAlternatingRows: [[dict objectForKey: CL_ALTERNATING_GRID] boolValue]];

        [SCLView setAlternatingRowColor: [NSColor colorWithCalibratedRed:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"RED"] floatValue]
                                                                   green:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"GREEN"] floatValue]
                                                                    blue:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"BLUE"] floatValue]
                                                                   alpha:[[dict objectForKey: CL_OPACITY] floatValue]]];
		// iacas - 12/22/2002
		if([[dict objectForKey: CL_OPACITY] floatValue] < 100.0)
			[[SCLView window] setOpaque:NO];
		
        [SCLView setNeedsDisplay:YES];
    }    
}*/
/*- (void)itemDidExpandOrCollapse:(NSNotification *)notification
{
//    [self desiresNewSize];
}*/

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

@end





