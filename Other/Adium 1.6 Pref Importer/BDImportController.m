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

#import "BDImportController.h"

#import "BDFireImporter.h"
#import "BDProteusImporter.h"
#import "BDiChatImporter.h"
#import "BDAdiumImporter.h"
#import "BDGaimImporter.h"

@implementation BDImportController

//Data paths for other clients



- (id)init
{
	
	proteus =	[[[BDProteusImporter alloc] initWithIdentifier:@"Proteus"] retain];
	iChat	=	[[[BDiChatImporter alloc] initWithIdentifier:@"iChat"] retain];
	fire	=	[[[BDFireImporter alloc] initWithIdentifier:@"Fire"] retain];
	adium	=	[[[BDAdiumImporter alloc] initWithIdentifier:@"Adium"] retain];
	gaim	=	[[[BDGaimImporter alloc] initWithIdentifier:@"GAIM"] retain];
	
	accountList = [[[NSMutableArray alloc] init] retain];
	
	
	return self;
}

- (void)awakeFromNib
{	
	[self configureProteusTab];
	
	[panel_importPanel setDelegate:self];
	[panel_importPanel makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark Importer Configuration

- (void)configureProteusTab
{
	//Configure the Proteus Log Importer
	[image_clientImage setImage:[proteus iconAtSize:48]];
	
	NSMenu *serviceMenu = [[[NSMenu alloc] initWithTitle:@"Service"] autorelease];
	[serviceMenu addItemWithTitle:@"AIM" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@".Mac" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"MSN" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"ICQ" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Zephyr" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Gadu Gadu" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Yahoo" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Yahoo Japan" action:nil keyEquivalent:@""];
	[[[table_proteusAccounts tableColumnWithIdentifier:@"ACCOUNT_SERVICE"] dataCell] setAltersStateOfSelectedItem:YES];
	[[[table_proteusAccounts tableColumnWithIdentifier:@"ACCOUNT_SERVICE"] dataCell] setMenu:serviceMenu];
	
	NSMutableDictionary *account = [[NSMutableDictionary alloc] init];
	[account setObject:@"Brandon" forKey:@"ACCOUNT_NAME"];
	[account setObject:[NSNumber numberWithInt:[serviceMenu indexOfItemWithTitle:@"MSN"]] forKey:@"ACCOUNT_SERVICE"];
	[accountList addObject:account];
	[table_proteusAccounts reloadData];
}

- (void)configureiChatTab
{
}

- (void)configureFireTab
{
}

- (void)configureGaimTab
{
}



#pragma mark -
#pragma mark TableView Delegate Methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView  {
    return [accountList count];  

} 

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row  
{    
	return [[accountList objectAtIndex:row] objectForKey:[tableColumn identifier]];
}  


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    //NSDictionary   *accountsDict = [accountList objectAtIndex:row];
	int serviceValue;
	if ([[tableColumn identifier] isEqualTo:@"ACCOUNT_SERVICE"]) {
		serviceValue = [[[accountList objectAtIndex:row] objectForKey:@"ACCOUNT_SERVICE"] intValue];
		[cell selectItemAtIndex:serviceValue];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	
}

- (void)tableView:(NSTableView *)tableView	setObjectValue:(id)value 
											forTableColumn:(NSTableColumn *)column 
													   row:(int)row
{
	if ([[column identifier] isEqualTo:@"ACCOUNT_SERVICE"])
	{
		[[accountList objectAtIndex:row] setObject:value forKey:@"ACCOUNT_SERVICE"];
	}
}

/* table view delegate methods we have NOT implemented:

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn;

- (void) tableView:(NSTableView*)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
- (void) tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn;
- (void) tableView:(NSTableView*)tableView didDragTableColumn:(NSTableColumn *)tableColumn;

- (void)tableViewColumnDidMove:(NSNotification *)notification;
- (void)tableViewColumnDidResize:(NSNotification *)notification;
- (void)tableViewSelectionIsChanging:(NSNotification *)notification;
    */

// ---------- Action Methods ----------

@end
