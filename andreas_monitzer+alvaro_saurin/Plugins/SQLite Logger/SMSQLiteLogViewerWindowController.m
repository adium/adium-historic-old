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

#import "SMSQLiteLogViewerWindowController.h"
#import "SMSQLiteLoggerPlugin.h"
#import "SMLoggerContact.h"
#import "SMLoggerConversation.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIAlternatingRowTableView.h>

#define LOG_VIEWER_NIB					@"SQLiteLogViewer"
#define KEY_LOG_VIEWER_WINDOW_FRAME		@"SQLite Log Viewer Frame"
#define TOOLBAR_SQLITE_LOG_VIEWER		@"SQLite Log Viewer Toolbar"

@implementation SMSQLiteLogViewerWindowController
- (id)initWithPlugin:(id)inPlugin {
	[super initWithWindowNibName:LOG_VIEWER_NIB];
	plugin = inPlugin;
	dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString] allowNaturalLanguage:YES];
	return self;
}

- (void)dealloc {
	[dateFormatter release];
	[super dealloc];
}

- (id)plugin {
	return plugin;
}

- (void)windowDidLoad {
	[super windowDidLoad];
	[drawer_contacts open:nil];
	[self installToolbar];
}

- (NSString *)adiumFrameAutosaveName
{
	return KEY_LOG_VIEWER_WINDOW_FRAME;
}

- (void)updateConversations {
	[table_conversations reloadData];
	[self tableViewSelectionDidChange:nil];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[plugin conversationList] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	SMLoggerConversation *currentConversation = [[plugin conversationList] objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"Service"]) {
		NSImage *service = [[currentConversation account] serviceImage];
		return (service ? service : [[[NSImage alloc] initWithSize:NSMakeSize(1,1)] autorelease]);
    }
	else if ([[tableColumn identifier] isEqualToString:@"From"]) {
		SMLoggerContact *contact = [currentConversation account];
		if (![contact displayName] || [[contact displayName] isEqualToString:[contact identifier]]) {
			return [contact identifier];
		}
		else {
			return [NSString stringWithFormat:@"%@ (%@)", [contact displayName], [contact identifier]];
		}
	}
	else if ([[tableColumn identifier] isEqualToString:@"To"]) {
		SMLoggerContact *contact = [currentConversation other];
		if (![contact displayName] || [[contact displayName] isEqualToString:[contact identifier]]) {
			return [contact identifier];
		}
		else {
			return [NSString stringWithFormat:@"%@ (%@)", [contact displayName], [contact identifier]];
		}
	}
	else if ([[tableColumn identifier] isEqualToString:@"Date"]) {
		return [dateFormatter stringForObjectValue:[currentConversation day]];
	}
	else {
		return @"";
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int selectedRow = [table_conversations selectedRow];
	
	if (selectedRow >= 0 && selectedRow < [table_conversations numberOfRows]) {
		[[textView_log textStorage] setAttributedString:[plugin conversationContents:[[plugin conversationList] objectAtIndex:selectedRow]]];
	} else {
		[[textView_log textStorage] setAttributedString:[[[NSAttributedString alloc] init] autorelease]];
	}
	[textView_log scrollRangeToVisible:NSMakeRange(0,0)];
}

#pragma mark Toolbar
- (void)installToolbar
{	
    NSToolbar 		*toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_SQLITE_LOG_VIEWER] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    toolbarItems = [[NSMutableDictionary alloc] init];
	
	//Toggle Drawer
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"toggledrawer"
											 label:AILocalizedString(@"Contacts",nil)
									  paletteLabel:AILocalizedString(@"Contacts Drawer",nil)
										   toolTip:AILocalizedString(@"Show/Hide the Contacts Drawer",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"showdrawer" forClass:[self class]]
											action:@selector(toggleDrawer:)
											  menu:nil];
	/*Delete Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"delete"
											 label:DELETE
									  paletteLabel:DELETE
										   toolTip:AILocalizedString(@"Delete selected log",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
											action:@selector(deleteSelectedLog:)
											  menu:nil];
	
	//Delete All Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"deleteall"
											 label:DELETEALL
									  paletteLabel:DELETEALL
										   toolTip:AILocalizedString(@"Delete all logs",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
											action:@selector(deleteAllLogs:)
											  menu:nil];
	
	//Search
	[self window]; //Ensure the window is loaded, since we're pulling the search view from our nib
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"search"
														  label:SEARCH
												   paletteLabel:SEARCH
														toolTip:AILocalizedString(@"Search or filter logs",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:view_SearchField
														 action:@selector(updateSearch:)
														   menu:nil];
	
	[toolbarItem setMinSize:NSMakeSize(150, NSHeight([view_SearchField frame]))];
	[toolbarItem setMaxSize:NSMakeSize(230, NSHeight([view_SearchField frame]))];
	[toolbarItems setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];
	
	//Toggle Emoticons
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"toggleemoticons"
											 label:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)
									  paletteLabel:AILocalizedString(@"Show/Hide Emoticons",nil)
										   toolTip:AILocalizedString(@"Show or hide emoticons in logs",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]
											action:@selector(toggleEmoticonFiltering:)
											  menu:nil];*/
	
	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
/*    return [NSArray arrayWithObjects:@"delete", @"toggleemoticons", NSToolbarFlexibleSpaceItemIdentifier, @"search", NSToolbarSeparatorItemIdentifier, @"deleteall", @"toggledrawer", nil];*/
	return [NSArray arrayWithObjects:NSToolbarFlexibleSpaceItemIdentifier, @"toggledrawer", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

- (IBAction)toggleDrawer:(id)sender
{	
    [drawer_contacts toggle:sender];
}
@end
