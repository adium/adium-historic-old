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

#import "SMContactsTable.h"
#import "SMSQLiteLogViewerWindowController.h"
#import "SMSQLiteLoggerPlugin.h"
#import "SMLoggerContact.h"
#import <AIUtilities/AIAlternatingRowTableView.h>

@implementation SMContactsTable
- (void)awakeFromNib {
	showingContacts = YES;
	[[adium notificationCenter] addObserver:self selector:@selector(updateTable:) name:LOGGER_DID_UPDATE_ACCOUNT_LIST object:nil];
	[[adium notificationCenter] addObserver:self selector:@selector(updateTable:) name:LOGGER_DID_UPDATE_OTHERS_LIST object:nil];
}

- (void)dealloc {
	[[adium notificationCenter] removeObserver:self];
	[super dealloc];
}

- (void)updateTable:(NSNotification *)aNotification {
	[table_contactList reloadData];
}

- (IBAction)switchTable:(id)sender {
	//Update our table
	showingContacts = ([[sender selectedItem] tag] == 0);
	[table_contactList reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	int numContacts;
	
	if (showingContacts)
		numContacts = [[[controller_logViewer plugin] others] count];
	else
		numContacts = [[[controller_logViewer plugin] accounts] count];	
			
	return numContacts;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if ([[tableColumn identifier] isEqualToString:@"service"]) {
		NSImage *service;
		if (showingContacts)
			service = [(SMLoggerContact *)[[[controller_logViewer plugin] others] objectAtIndex:row] serviceImage];
		else
			service = [(SMLoggerContact *)[[[controller_logViewer plugin] accounts] objectAtIndex:row] serviceImage];
		return (service ? service : [[[NSImage alloc] initWithSize:NSMakeSize(1,1)] autorelease]);
    }
	else if ([[tableColumn identifier] isEqualToString:@"name"]) {
		SMLoggerContact *contact;
		if (showingContacts)
			contact = [[[controller_logViewer plugin] others] objectAtIndex:row];
		else
			contact = [[[controller_logViewer plugin] accounts] objectAtIndex:row];
		if (![contact displayName] || [[contact displayName] isEqualToString:[contact identifier]]) {
			return [contact identifier];
		}
		else {
			return [NSString stringWithFormat:@"%@ (%@)", [contact displayName], [contact identifier]];
		}
	}
	else {
		return @"";
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int selectedRow = [table_contactList selectedRow];
	
	if (selectedRow >= 0 && selectedRow < [table_contactList numberOfRows]) {
		if (showingContacts) {
			[[controller_logViewer plugin] filterForContact:(SMLoggerContact *)[[[controller_logViewer plugin] others] objectAtIndex:selectedRow]];
		} else {
			[[controller_logViewer plugin] filterForAccount:(SMLoggerContact *)[[[controller_logViewer plugin] accounts] objectAtIndex:selectedRow]];
		}
	} else {
		[[controller_logViewer plugin] filterForNothing];
	}
	
	[controller_logViewer updateConversations];
}

/*
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    if (showingContacts) { // deleting a contact
        [self moveContactToTrash];
    } else { // deleting an account
        [self moveAccountToTrash];
    }
}*/
@end
