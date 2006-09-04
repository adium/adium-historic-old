//
//  ESGaimMeanwhileContactAdditionController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/29/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESGaimMeanwhileContactAdditionController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIServiceIcons.h>
#import <Adium/NDRunLoopMessenger.h>


//XXX This is close to a generic implementation.... this should be expanded to work for any search results.

@interface ESGaimMeanwhileContactAdditionController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict;
- (void)doubleClickInTableView:(id)sender;
- (oneway void)doRequestFieldsCbValue:(NSValue *)inCallBackValue
							  withUserDataValue:(NSValue *)inUserDataValue 
									fieldsValue:(NSValue *)inFieldsValue;	
@end

@implementation ESGaimMeanwhileContactAdditionController

+ (ESGaimMeanwhileContactAdditionController *)showContactAdditionListWithDict:(NSDictionary *)inInfoDict
{
	ESGaimMeanwhileContactAdditionController	*controller;
	
	if ((controller = [[self alloc] initWithWindowNibName:@"GaimMeanwhileContactAdditionWindow"
												 withDict:inInfoDict])) {
		
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
	}
	
	return controller;
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		infoDict = [inInfoDict retain];
	}
	
    return self;
}

- (void)dealloc
{
	[infoDict release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[textField_header setStringValue:AILocalizedString(@"An ambiguous user ID was entered",nil)];
	[textField_message setStringValue:[NSString stringWithFormat:
		AILocalizedString(@"The identifier '%@' may possibly refer to any of the following users. Please select the correct user from the list below.",nil),
		[infoDict objectForKey:@"Original Name"]]];
	[imageView_meanwhile setImage:[AIServiceIcons serviceIconForServiceID:@"Sametime"
																	 type:AIServiceIconLarge
																direction:AIIconNormal]];
	[button_OK setLocalizedString:AILocalizedString(@"OK",nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];
	
	[[[tableView_choices tableColumnWithIdentifier:@"name"] headerCell] setStringValue:AILocalizedString(@"Name", nil)];
	[[[tableView_choices tableColumnWithIdentifier:@"id"] headerCell] setStringValue:AILocalizedString(@"Sametime ID", nil)];
	[tableView_choices reloadData];
	[tableView_choices setTarget:self];
	[tableView_choices setDoubleAction:@selector(doubleClickInTableView:)];
	[self tableViewSelectionDidChange:nil];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	GaimNotifySearchResults *results = [[infoDict objectForKey:@"GaimNotifySearchResultsValue"] pointerValue];
	return gaim_notify_searchresults_get_rows_count(results);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	GaimNotifySearchResults *results = [[infoDict objectForKey:@"GaimNotifySearchResultsValue"] pointerValue];
	GList *rowList = gaim_notify_searchresults_row_get(results, rowIndex);

	NSString *identifier = [aTableColumn identifier];

	if ([identifier isEqualToString:@"name"]) {
		const char *name = g_list_nth_data(rowList, 0);
		return [NSString stringWithUTF8String:name];

	} else if ([identifier isEqualToString:@"id"]) {
		const char *sametimeID = g_list_nth_data(rowList, 1);
		return [NSString stringWithUTF8String:sametimeID];

	} else {
		return @"";
	}
}

/*!
 * @brief Only enable the OK button if there is a selection
 */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int selectedRow = [tableView_choices selectedRow];
	[button_OK setEnabled:(selectedRow != -1)];
}

- (IBAction)pressedButton:(id)sender
{
	if (sender == button_OK) {
		GaimNotifySearchResults		*results = [[infoDict objectForKey:@"GaimNotifySearchResultsValue"] pointerValue];
		int							selectedRow = [tableView_choices selectedRow];
		GList						*rowList = gaim_notify_searchresults_row_get(results, selectedRow);
		GList						*buttons = results->buttons;

		GaimNotifySearchButton		*button;

		//IM is first; Add is 2nd
		button = g_list_nth_data(buttons, 1);
		
		button->callback([[infoDict objectForKey:@"GaimConnection"] pointerValue], rowList, [[infoDict objectForKey:@"userData"] pointerValue]);

		[infoDict release]; infoDict = nil;
		[[self window] close];

	} else if (sender == button_cancel) {
		gaim_notify_close(GAIM_NOTIFY_SEARCHRESULTS, self);
		[[self window] performClose:nil];
	}
}

- (void)windowWillClose:(id)sender
{
	gaim_notify_close(GAIM_NOTIFY_SEARCHRESULTS, self);
}

/*!
 * @brief Double click works the same as pressing OK
 */
- (void)doubleClickInTableView:(id)sender
{
	if ([tableView_choices selectedRow] != -1) {
		[self pressedButton:button_OK];
	}
}

@end
