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
}

- (void)dealloc
{
	[blankImage release];
	
	[super dealloc];
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

	}
}

//
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int selectedRow = [table_filterList selectedRow];
	
	if(selectedRow >= 0 && selectedRow < [table_filterList numberOfRows]){
		if(showingContacts){
            [controller_LogViewer setSearchString:[[controller_LogViewer toArray] objectAtIndex:selectedRow]
																						   mode:LOG_SEARCH_TO];
		}else{
            [controller_LogViewer setSearchString:[[controller_LogViewer fromArray] objectAtIndex:selectedRow]
											 mode:LOG_SEARCH_FROM];
		}
	}else{
		[controller_LogViewer setSearchString:@""];
	}
}

//Switch the displayed filter
- (IBAction)switchTable:(id)sender
{
	//Update our table
	showingContacts = ([[popup_filterType selectedItem] tag] == 0);
	[table_filterList reloadData];

    //Reset any log searching
	[controller_LogViewer setSearchString:@""];
}

@end
