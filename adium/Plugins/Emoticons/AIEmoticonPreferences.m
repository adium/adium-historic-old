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

#import "AIEmoticonPreferences.h"
#import "AIEmoticonsPlugin.h"
#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPackCell.h"

#define	EMOTICON_PREF_NIB		@""
#define EMOTICON_PREF_TITLE		@"Emoticons/Smilies"
#define	EMOTICON_PACK_DRAG_TYPE         @"AIEmoticonPack"
#define EMOTICON_MIN_ROW_HEIGHT         17

@interface AIEmoticonPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_buildEmoticonSetMenu;
- (void)_configureEmoticonListForSelection;
@end

@implementation AIEmoticonPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Emoticons);
}
- (NSString *)label{
    return(@"Emoticons");
}
- (NSString *)nibName{
    return(@"EmoticonPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    //Pack table
    [table_emoticonPacks registerForDraggedTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];
    [[[table_emoticonPacks tableColumns] objectAtIndex:0] setDataCell:[[[AIEmoticonPackCell alloc] init] autorelease]];
    [table_emoticonPacks selectRow:0 byExtendingSelection:NO];
    
    //Emoticons table
    NSButtonCell    *checkCell = [[[NSButtonCell alloc] init] autorelease];
    [checkCell setButtonType:NSSwitchButton];
    [checkCell setControlSize:NSSmallControlSize];
    [checkCell setTitle:@""];
    [checkCell setRefusesFirstResponder:YES];
    [[table_emoticons tableColumnWithIdentifier:@"Enabled"] setDataCell:checkCell];
    [[table_emoticons tableColumnWithIdentifier:@"Image"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
    [table_emoticons setDrawsAlternatingRows:YES];
    
    //Configure our buttons
    [button_addEmoticons setImage:[AIImageUtilities imageNamed:@"plus" forClass:[self class]]];
    [button_removeEmoticons setImage:[AIImageUtilities imageNamed:@"minus" forClass:[self class]]];
    
    //Observe prefs    
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    //
    [self _configureEmoticonListForSelection];
}

- (void)viewWillClose
{
    //Flush all the images we loaded
    [plugin flushEmoticonImageCache];
}

//Returns a menu for the emoticon set popup
- (void)_buildEmoticonSetMenu
{
    NSMenu          *setMenu = [button_addEmoticons menu];
    NSEnumerator    *enumerator;
    AIEmoticonPack  *pack;
    
    //Empty the menu
    [setMenu removeAllItemsButFirst];
   
    //Item for each available set
    enumerator = [[plugin availableEmoticonPacks] objectEnumerator];
    while(pack = [enumerator nextObject]){
        if(![[plugin activeEmoticonPacks] containsObject:pack] && [[pack emoticons] count] > 0){
            NSMenuItem  *menuItem;
            
            menuItem = [[NSMenuItem alloc] initWithTitle:[pack name]
                                                  target:self
                                                  action:@selector(addEmoticonPack:)
                                           keyEquivalent:@""];
            [menuItem setRepresentedObject:pack];
            [menuItem setImage:[[[[[pack emoticons] objectAtIndex:0] image] copy] autorelease]]; //Must use a copy, since the menu will flip our image and not flip it back when done.

            [setMenu addItem:menuItem];
        }
    }
}

//Configure the emoticon table view for the currently selected pack
- (void)_configureEmoticonListForSelection
{
    int         rowHeight = EMOTICON_MIN_ROW_HEIGHT;
    
    //Remember the selected pack
    if([table_emoticonPacks numberOfSelectedRows] == 1 && [table_emoticonPacks selectedRow] != -1){
        selectedEmoticonPack = [[plugin activeEmoticonPacks] objectAtIndex:[table_emoticonPacks selectedRow]];
    }else{
        selectedEmoticonPack = nil;
    }

    //Set the row height to the average height of the emoticons
    if(selectedEmoticonPack){
        NSEnumerator    *enumerator;
        AIEmoticon      *emoticon;
        int             totalHeight = 0;
        
        enumerator = [[selectedEmoticonPack emoticons] objectEnumerator];
        while(emoticon = [enumerator nextObject]){
            totalHeight += [[emoticon image] size].height;
        }

        rowHeight = totalHeight / [[selectedEmoticonPack emoticons] count];
        if(rowHeight < EMOTICON_MIN_ROW_HEIGHT) rowHeight = EMOTICON_MIN_ROW_HEIGHT;
    }
    
    //Update the table
    [table_emoticons setRowHeight:rowHeight];
    [table_emoticons reloadData];

    //Update header
    if(selectedEmoticonPack){
        [textField_packTitle setStringValue:[NSString stringWithFormat:@"Emoticons in %@",[selectedEmoticonPack name]]];
    }else{
        [textField_packTitle setStringValue:@""];
    }
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_EMOTICONS compare:[[notification userInfo] objectForKey:@"Group"]] == 0){        
        //Refresh our emoticon tables
        [table_emoticonPacks reloadData];
        [self _configureEmoticonListForSelection];
    
        //Update our add menu
        [self _buildEmoticonSetMenu];
    }
}

//Remove the selected set
- (IBAction)removeEmoticons:(id)sender
{
    NSEnumerator    *enumerator = [table_emoticonPacks selectedRowEnumerator];
    NSNumber        *row;
    NSMutableArray  *selectedEmoticonSets = [NSMutableArray array];
    
    while(row = [enumerator nextObject]){
        [selectedEmoticonSets addObject:[[plugin activeEmoticonPacks] objectAtIndex:[row intValue]]];
    }

    if([selectedEmoticonSets count]){
        [plugin removeActiveEmoticonPacks:selectedEmoticonSets];
    }
}

//Add an emoticon set (called by add popup menu)
- (void)addEmoticonPack:(NSMenuItem *)menuItem
{
    AIEmoticonPack  *pack = [menuItem representedObject];
    
    [plugin addActiveEmoticonPacks:[NSArray arrayWithObject:pack] toIndex:0];
    [table_emoticonPacks selectRow:[[plugin activeEmoticonPacks] indexOfObject:pack] byExtendingSelection:NO];
}


//Emoticon table view
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == table_emoticonPacks){
        return([[plugin activeEmoticonPacks] count]);
    }else{
        return([[selectedEmoticonPack emoticons] count]);
    }
}

//Returns a dimmed, attributed version of the passed string
- (NSAttributedString *)_dimString:(NSString *)inString center:(BOOL)center
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    
    if(center){
        NSMutableParagraphStyle	*paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    }

    return([[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease]);
}

//Emoticon table view delegates
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if(tableView == table_emoticonPacks){
        return([[plugin activeEmoticonPacks] objectAtIndex:row]);
    }else{
        NSString    *identifier = [tableColumn identifier];
        AIEmoticon  *emoticon = [[selectedEmoticonPack emoticons] objectAtIndex:row];
        
        if([identifier compare:@"Enabled"] == 0){
            return([NSNumber numberWithBool:[emoticon isEnabled]]);
            
        }else if([identifier compare:@"Image"] == 0){
            return([emoticon image]);
            
        }else if([identifier compare:@"Name"] == 0){
            if([emoticon isEnabled]) return([emoticon name]);
            else return([self _dimString:[emoticon name] center:NO]);
            
        }else{// if([identifier compare:@"String"] == 0){
            if([emoticon isEnabled]) return([[emoticon textEquivalents] objectAtIndex:0]);
            else return([self _dimString:[[emoticon textEquivalents] objectAtIndex:0] center:YES]);
        }

    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if(tableView == table_emoticons && [@"Enabled" compare:[tableColumn identifier]] == 0){
        AIEmoticon  *emoticon = [[selectedEmoticonPack emoticons] objectAtIndex:row];

        [plugin setEmoticon:emoticon inPack:selectedEmoticonPack enabled:[object intValue]];
    }
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    if(tableView == table_emoticonPacks){
        dragRows = rows;        
        [pboard declareTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE] owner:self];
        [pboard setString:@"dragPack" forType:EMOTICON_PACK_DRAG_TYPE];
        
        return(YES);
    }else{
        return(NO);
    }
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
{
    if(tableView == table_emoticonPacks){
        if(op == NSTableViewDropAbove && row != -1){
            return(NSDragOperationMove);
        }else{
            return(NSDragOperationNone);
        }
    }else{
        return(NSDragOperationNone);
    }
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
{
    if(tableView == table_emoticonPacks){
        NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];
        
        if([avaliableType compare:EMOTICON_PACK_DRAG_TYPE] == 0){
            NSMutableArray  *movedPacks = [NSMutableArray array]; //Keep track of the packs we've moved
            NSEnumerator    *enumerator;
            NSNumber        *dragRow;
            AIEmoticonPack  *pack;
            
            //Move
            enumerator = [dragRows objectEnumerator];
            while(dragRow = [enumerator nextObject]){
                [movedPacks addObject:[[plugin activeEmoticonPacks] objectAtIndex:[dragRow intValue]]];
            }
            [plugin moveActiveEmoticonPacks:movedPacks toIndex:row];
            
            //Select the moved packs
            [tableView deselectAll:nil];
            enumerator = [movedPacks objectEnumerator];
            while(pack = [enumerator nextObject]){
                [tableView selectRow:[[plugin activeEmoticonPacks] indexOfObject:pack] byExtendingSelection:YES];
            }
            
            return(YES);
        }else{
            return(NO);
        }
    }else{
        return(NO);
    }
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    if(tableView == table_emoticonPacks){
        [self removeEmoticons:nil];
    }
}

- (void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    if([notification object] == table_emoticonPacks){
        [self _configureEmoticonListForSelection];
    }else{
        //I don't want the emoticon table to display it's selection.
        //Returning NO from 'shouldSelectRow' would work, but if we do that
        //the checkbox cells stop working.  The best solution I've come up with
        //so far is to just force a deselect here :( .
        [table_emoticons deselectAll:nil];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{    
    if([notification object] == table_emoticonPacks){
        [self _configureEmoticonListForSelection];
    }else{
        //I don't want the emoticon table to display it's selection.
        //Returning NO from 'shouldSelectRow' would work, but if we do that
        //the checkbox cells stop working.  The best solution I've come up with
        //so far is to just force a deselect here :( .
        [table_emoticons deselectAll:nil];
    }
}

@end
