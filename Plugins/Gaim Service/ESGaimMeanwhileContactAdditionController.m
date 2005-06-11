//
//  ESGaimMeanwhileContactAdditionController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/29/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimMeanwhileContactAdditionController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIServiceIcons.h>
#import <Adium/NDRunLoopMessenger.h>

/* resolved id for Meanwhile */
struct resolved_id {
	char *id;
	char *name;
};

@interface ESGaimMeanwhileContactAdditionController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict;
@end

@implementation ESGaimMeanwhileContactAdditionController

+ (void)showContactAdditionListWithDict:(NSDictionary *)inInfoDict
{
	ESGaimMeanwhileContactAdditionController	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"GaimMeanwhileContactAdditionWindow"
											withDict:inInfoDict];
	
	[controller showWindow:nil];
	[[controller window] makeKeyAndOrderFront:nil];	
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		infoDict = [inInfoDict retain];
	}
	
    return(self);
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
	
	[tableView_choices reloadData];
	[tableView_choices setTarget:self];
	[tableView_choices setDoubleAction:@selector(doubleClickInTableView:)];
	[self tableViewSelectionDidChange:nil];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[infoDict objectForKey:@"Possible Users"] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	struct resolved_id	*res = (struct resolved_id	*)([[[infoDict objectForKey:@"Possible Users"] objectAtIndex:rowIndex] pointerValue]);
	
	return [NSString stringWithUTF8String:res->name];	
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
		struct resolved_id		*res;
		int						selectedRow = [tableView_choices selectedRow];
		GaimRequestField		*field = [[infoDict objectForKey:@"listFieldValue"] pointerValue];

		res = (struct resolved_id *)([[[infoDict objectForKey:@"Possible Users"] objectAtIndex:selectedRow] pointerValue]);

		//Clear the selection
		gaim_request_field_list_clear_selected(field);
		
		//Now set the selection
		gaim_request_field_list_add_selected(field, res->name);
		
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestFieldsCbValue:withUserDataValue:fieldsValue:)
											  withObject:[infoDict objectForKey:@"OK Callback"]
											  withObject:[infoDict objectForKey:@"userData"]
											  withObject:[infoDict objectForKey:@"fieldsValue"]];

		[infoDict release]; infoDict = nil;
		[[self window] close];

	} else if (sender == button_cancel) {
		[[self window] performClose:nil];
	}
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

/*!
 * @brief Call the gaim callback to finish up the window
 *
 * @param inCallBackValue The cb to use
 * @param inUserDataValue Original user data
 * @param inFieldsValue The entire GaimRequestFields pointer originally passed
 */
- (oneway void)gaimThreadDoRequestFieldsCbValue:(NSValue *)inCallBackValue
							 withUserDataValue:(NSValue *)inUserDataValue 
								   fieldsValue:(NSValue *)inFieldsValue
{	
	GaimRequestFieldsCb callBack = [inCallBackValue pointerValue];
	if (callBack) {
		callBack([inUserDataValue pointerValue], [inFieldsValue pointerValue]);
	}	
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	if (infoDict) {
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoRequestFieldsCbValue:withUserDataValue:fieldsValue:)
											  withObject:[infoDict objectForKey:@"Cancel Callback"]
											  withObject:[infoDict objectForKey:@"userData"]
											  withObject:[infoDict objectForKey:@"fieldsValue"]];
	}
	
	[self autorelease];
}


@end
