#import "BGContactsTable.h"

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
            [self searchForTo:nil];
        }
        else{
            [controller_LogViewer resetSearch];
        }
    }
    else{
        if([table_accounts selectedRow] != -1){
            [self searchForFrom:nil];
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

-(IBAction)searchForFrom:(id)sender
{
    [controller_LogViewer setSearchString:[[controller_LogViewer fromArray] objectAtIndex:[table_accounts selectedRow]] mode:LOG_SEARCH_FROM];
}

-(IBAction)searchForTo:(id)sender
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
