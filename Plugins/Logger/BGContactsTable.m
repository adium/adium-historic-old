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

#import "BGContactsTable.h"

@implementation BGContactsTable

//
- (void)awakeFromNib
{
	showingContacts = YES;
	blankImage = [[NSImage alloc] initWithSize:NSMakeSize(16,16)];
	// Build the popup filter menu
	[[[popup_filterType menu] addItemWithTitle:AILocalizedString(@"Contacts",nil) target:self action:@selector(switchTable:) keyEquivalent:@""] setTag:0];
	[[[popup_filterType menu] addItemWithTitle:AILocalizedString(@"Accounts",nil) target:self action:@selector(switchTable:) keyEquivalent:@""] setTag:1];
	// Need to remove the minimal menuitem needed in IB
	[[popup_filterType menu] removeItemAtIndex:0];
}

- (void)dealloc
{
	[blankImage release];
	
	[super dealloc];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	return YES;
}

//
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(showingContacts){
        return [[controller_LogViewer toArray] count];
	}else{
        return [[controller_LogViewer fromArray] count];
	}
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if([[tableColumn identifier] isEqual:@"service"]){
		NSArray	*serviceArray = (showingContacts ? [controller_LogViewer toServiceArray] : [controller_LogViewer fromServiceArray]);
		NSImage	*image = [AIServiceIcons serviceIconForServiceID:[serviceArray objectAtIndex:row]
                                                                    type:AIServiceIconSmall
                                                               direction:AIIconNormal];
		return(image ? image : blankImage);
			
    }else if([[tableColumn identifier] isEqual:@"name"]){
		if(showingContacts){
			return([[controller_LogViewer toArray] objectAtIndex:row]);
		}else{
			return([[controller_LogViewer fromArray] objectAtIndex:row]);
		}

	}else{
		return(@"");
	}
}

//
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int selectedRow = [table_filterList selectedRow];
	
	if(selectedRow >= 0 && selectedRow < [table_filterList numberOfRows]){
		if(showingContacts){
			[controller_LogViewer filterForContactName:[[controller_LogViewer toArray] objectAtIndex:selectedRow]];
		}else{
			[controller_LogViewer filterForAccountName:[[controller_LogViewer fromArray] objectAtIndex:selectedRow]];
		}
	}else{
		[controller_LogViewer filterForContactName:nil];
		[controller_LogViewer filterForAccountName:nil];
	}
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    if(showingContacts){ // deleting a contact
        [self moveContactToTrash];
    }else{ // deleting an account
        [self moveAccountToTrash];
    }
}

-(void)moveContactToTrash
{
    NSString	*name = [[[[controller_LogViewer toArray] objectAtIndex:[table_filterList selectedRow]] copy] autorelease];
    NSBeginAlertSheet([NSString stringWithFormat:@"Delete %@'s Logs", name],@"Delete",@"Cancel",@"",[controller_LogViewer window], self, 
                      @selector(trashContactConfirmSheetDidEnd:returnCode:contextInfo:), nil, nil, 
                      @"Are you sure you want to delete any logs of past conversations with %@? These items will be moved to the Trash.",name,name);
    
}

- (void)trashContactConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSOKButton) {
        int dLoop = 0;
        // loop through all accounts & find this contact, remove as needed
        // -> if you can think of a more efficient solution please do, this is all that came to mind
        while(dLoop < [[controller_LogViewer fromArray] count])
        {
            NSString *deleteString = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@/%@/", [[controller_LogViewer fromServiceArray] objectAtIndex:dLoop], [[controller_LogViewer fromArray] objectAtIndex:dLoop], [[controller_LogViewer toArray] objectAtIndex:[table_filterList selectedRow]]]];
            if([[NSFileManager defaultManager] fileExistsAtPath:deleteString])
            {
                [[NSFileManager defaultManager] trashFileAtPath:deleteString];
            } 
            dLoop++;
        }
        [controller_LogViewer rebuildIndices];
        [table_filterList reloadData];
        [self tableViewSelectionDidChange:nil];
    }
}

-(void)moveAccountToTrash
{
    NSString	*name = [[[[controller_LogViewer fromArray] objectAtIndex:[table_filterList selectedRow]] copy] autorelease];
    NSBeginAlertSheet([NSString stringWithFormat:@"Delete %@'s Logs", name],@"Delete",@"Cancel",@"",[controller_LogViewer window], self, 
                      @selector(trashAccountConfirmSheetDidEnd:returnCode:contextInfo:), nil, nil, 
                      @"Are you sure you want to delete your %@ account's folder and all prior conversations with all contacts? This will be moved to the Trash.", name);
}

- (void)trashAccountConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSOKButton) {
        [[NSFileManager defaultManager] trashFileAtPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [[controller_LogViewer fromServiceArray] objectAtIndex:[table_filterList selectedRow]], [[controller_LogViewer fromArray] objectAtIndex:[table_filterList selectedRow]]]]];
        [controller_LogViewer rebuildIndices];
        [table_filterList reloadData];
    }
}

//Switch the displayed filter
- (IBAction)switchTable:(id)sender
{
	//Update our table
	showingContacts = ([[popup_filterType selectedItem] tag] == 0);
	[table_filterList reloadData];

    //Reset any log searching
	[controller_LogViewer filterForContactName:nil];
	[controller_LogViewer filterForAccountName:nil];
}

@end
