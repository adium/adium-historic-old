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

@interface BGContactsTable (PRIVATE)
-(void)searchForFrom;
-(void)searchForTo;
@end

@implementation BGContactsTable

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if([[tableColumn identifier] isEqual:@"spacer"])
    {
        return @" ";
    }
    else if([[tableColumn identifier] isEqual:@"service"]){
        return [[[adium accountController] firstServiceTypeWithServiceID:[[controller_LogViewer serviceArray] objectAtIndex:row]] menuImage];
    }
    else if([[tableColumn identifier] isEqual:@"account"]){
        return [[controller_LogViewer fromArray] objectAtIndex:row];
    }
    else if([[tableColumn identifier] isEqual:@"contact"]){
        return [[controller_LogViewer toArray] objectAtIndex:row];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([[popup_switcherThingie selectedItem] tag] == 0){
        if([table_contacts selectedRow] != -1){
            [self searchForTo];
        }
        else{
            [controller_LogViewer resetSearch];
        }
    }
    else{
        if([table_accounts selectedRow] != -1){
            [self searchForFrom];
        }
        else{
            [controller_LogViewer resetSearch];
        }
    }
}

-(IBAction)switchTable:(id)sender
{
    [tabs_hiddenLogSwitch selectTabViewItemAtIndex:[sender tag]];
    [controller_LogViewer resetSearch];
}

-(void)searchForFrom
{
    [controller_LogViewer setSearchString:[[controller_LogViewer fromArray] objectAtIndex:[table_accounts selectedRow]] mode:LOG_SEARCH_FROM];
}

-(void)searchForTo
{
    [controller_LogViewer setSearchString:[[controller_LogViewer toArray] objectAtIndex:[table_contacts selectedRow]] mode:LOG_SEARCH_TO];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == table_accounts)
    {
        return [[controller_LogViewer fromArray] count];
    }
    else{
        return [[controller_LogViewer toArray] count];
    }
}

@end
