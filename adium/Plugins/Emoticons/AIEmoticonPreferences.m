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

#import "AIEmoticonPreferences.h"
#import "AIEmoticonsPlugin.h"
#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPackCell.h"

#define	EMOTICON_PREF_NIB               @""
#define	EMOTICON_PACK_DRAG_TYPE         @"AIEmoticonPack"
#define EMOTICON_MIN_ROW_HEIGHT         17
#define EMOTICON_PACKS_TOOLTIP          AILocalizedString(@"Reorder emoticon packs by dragging. Packs get used based on the order from top to bottom.",nil)
@interface AIEmoticonPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureEmoticonListForSelection;
@end

@implementation AIEmoticonPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Emoticons);
}
- (NSString *)label{
    return(AILocalizedString(@"Emoticons","Emoticons/Smilies"));
}
- (NSString *)nibName{
    return(@"EmoticonPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    //Pack table
    [table_emoticonPacks registerForDraggedTypes:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];

    [[table_emoticonPacks tableColumnWithIdentifier:@"Emoticons"] setDataCell:[[[AIEmoticonPackCell alloc] initWithPlugin:plugin] autorelease]];
    [table_emoticonPacks selectRow:0 byExtendingSelection:NO];
    [table_emoticonPacks setToolTip:EMOTICON_PACKS_TOOLTIP];
	
    //Emoticons table
    checkCell = [[NSButtonCell alloc] init];
    [checkCell setButtonType:NSSwitchButton];
    [checkCell setControlSize:NSSmallControlSize];
    [checkCell setTitle:@""];
    [checkCell setRefusesFirstResponder:YES];
    [[table_emoticons tableColumnWithIdentifier:@"Enabled"] setDataCell:checkCell];
    [[table_emoticons tableColumnWithIdentifier:@"Image"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
    [table_emoticons setDrawsAlternatingRows:YES];
        
    //Observe prefs    
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    //Configure the right pane to display the emoticons for the current selection
    [self _configureEmoticonListForSelection];
	
	//Redisplay the emoticons after an small delay so the sample emoticons line up properly
	//since the desired width isn't known by AIEmoticonPackCell until once through the list of packs
	[table_emoticonPacks performSelector:@selector(display) withObject:nil afterDelay:0.0001];
}

- (void)viewWillClose
{
	[checkCell release]; checkCell = nil;
	
	[[adium notificationCenter] removeObserver:self];
	
    //Flush all the images we loaded
    [plugin flushEmoticonImageCache];
}

//Configure the emoticon table view for the currently selected pack
- (void)_configureEmoticonListForSelection
{
    int         rowHeight = EMOTICON_MIN_ROW_HEIGHT;
    
    //Remember the selected pack
    if([table_emoticonPacks numberOfSelectedRows] == 1 && [table_emoticonPacks selectedRow] != -1){
        selectedEmoticonPack = [[plugin availableEmoticonPacks] objectAtIndex:[table_emoticonPacks selectedRow]];
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
    [table_emoticons reloadData];
    [table_emoticons setRowHeight:rowHeight];

    //Update header
    if(selectedEmoticonPack){
		//Enable the individual emoticon checks only if the selectedEmoticonPack is enabled
		[checkCell setEnabled:[selectedEmoticonPack isEnabled]];
		
        [textField_packTitle setStringValue:[NSString stringWithFormat:@"Emoticons in %@",[selectedEmoticonPack name]]];
    }else{
        [textField_packTitle setStringValue:@""];
    }
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_EMOTICONS isEqualToString:[[notification userInfo] objectForKey:@"Group"]]){        
        //Refresh our emoticon tables
        [table_emoticonPacks reloadData];
        [self _configureEmoticonListForSelection];
	}
}

//Emoticon table view
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == table_emoticonPacks){
        return([[plugin availableEmoticonPacks] count]);
    }else{
        return([[selectedEmoticonPack emoticons] count]);
    }
}

//Returns a dimmed, attributed version of the passed string
- (NSAttributedString *)_dimString:(NSString *)inString center:(BOOL)center
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    
    if(center){
        [attributes setObject:[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment]
		       forKey:NSParagraphStyleAttributeName];
    }

    return([[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease]);
}

//Emoticon table view delegates
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if(tableView == table_emoticonPacks){
		AIEmoticonPack *pack = [[plugin availableEmoticonPacks] objectAtIndex:row];
		
		return(pack);
			
    }else{
		NSString    *identifier = [tableColumn identifier];
        AIEmoticon  *emoticon = [[selectedEmoticonPack emoticons] objectAtIndex:row];
        
        if([identifier isEqualToString:@"Enabled"]){
            return([NSNumber numberWithBool:[emoticon isEnabled]]);
            
        }else if([identifier isEqualToString:@"Image"]){
            return([emoticon image]);
            
        }else if([identifier isEqualToString:@"Name"]){
            if([selectedEmoticonPack isEnabled] && [emoticon isEnabled]){
				return([emoticon name]);
            }else{
				return([self _dimString:[emoticon name] center:NO]);
			}
            
        }else{// if([identifier compare:@"String"] == 0){
			NSArray *textEquivalents = [emoticon textEquivalents];
			if ([textEquivalents count]){
				if([selectedEmoticonPack isEnabled] && [emoticon isEnabled]){
					return([textEquivalents objectAtIndex:0]);
				}else{
					return([self _dimString:[textEquivalents objectAtIndex:0] center:YES]);
				}
			}else{
				return @"";
			}
        }

    }
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self moveSelectedPacksToTrash]; 
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == table_emoticons && [@"Enabled" isEqualToString:[tableColumn identifier]]) {
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

-(void)moveSelectedPacksToTrash
{
    NSBeginAlertSheet(@"Delete Emoticon Pack",@"Delete",@"Cancel",@"",[[self view] window], self, 
                      @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:), nil, nil, 
                      @"Are you sure you want to delete the %@ Emoticon Pack? It will be moved to the Trash, which may take a moment, depending on its size.",[selectedEmoticonPack name]);
}

- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSOKButton) {
        NSEnumerator *selectedEnum = [table_emoticonPacks selectedRowEnumerator];
        int object;
        while(object = [[selectedEnum nextObject] intValue]) {
            NSString *currentEPPath = [[[plugin availableEmoticonPacks] objectAtIndex:object] path];
            // the plugin should then update and auto-propigate :)
            [[NSFileManager defaultManager] trashFileAtPath:currentEPPath];
		}
		
		[table_emoticonPacks deselectAll:nil];
        [plugin publicReset];
        [table_emoticonPacks reloadData];            
    }
}

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
{
    if(tableView == table_emoticonPacks){
        NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:EMOTICON_PACK_DRAG_TYPE]];
        
        if([avaliableType isEqualToString:EMOTICON_PACK_DRAG_TYPE]){
            NSMutableArray  *movedPacks = [NSMutableArray array]; //Keep track of the packs we've moved
            NSEnumerator    *enumerator;
            NSNumber        *dragRow;
            AIEmoticonPack  *pack;
            
            //Move
            enumerator = [dragRows objectEnumerator];
            while(dragRow = [enumerator nextObject]){
                [movedPacks addObject:[[plugin availableEmoticonPacks] objectAtIndex:[dragRow intValue]]];
            }
            [plugin moveEmoticonPacks:movedPacks toIndex:row];
            
			[tableView reloadData];
			
            //Select the moved packs
            [tableView deselectAll:nil];
            enumerator = [movedPacks objectEnumerator];
            while(pack = [enumerator nextObject]){
                [tableView selectRow:[[plugin availableEmoticonPacks] indexOfObject:pack] byExtendingSelection:NO];
            }
            
            return(YES);
        }else{
            return(NO);
        }
    }else{
        return(NO);
    }
}

/*
- (void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    if([notification object] == table_emoticonPacks){
        [self _configureEmoticonListForSelection];
    }else{
        //I don't want the emoticon table to display its selection.
        //Returning NO from 'shouldSelectRow' would work, but if we do that
        //the checkbox cells stop working.  The best solution I've come up with
        //so far is to just force a deselect here :( .
        [table_emoticons deselectAll:nil];
    }
}
*/

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([notification object] == table_emoticonPacks){
        [self _configureEmoticonListForSelection];
    }else{
        //I don't want the emoticon table to display its selection.
        //Returning NO from 'shouldSelectRow' would work, but if we do that
        //the checkbox cells stop working.  The best solution I've come up with
        //so far is to just force a deselect here :( .
        [table_emoticons deselectAll:nil];
    }
}
@end
