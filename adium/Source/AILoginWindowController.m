/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id: AILoginWindowController.m,v 1.5 2004/03/02 02:47:17 adamiser Exp $

#import "AILoginWindowController.h"
#import "AILoginController.h"

//Preference Keys
#define NEW_USER_NAME		@"New User"		//Default name of a new user
#define LOGIN_WINDOW_NIB	@"LoginSelect"		//Filename of the login window nib

@interface AILoginWindowController (PRIVATE)
- (id)initWithOwner:(id)inOwner windowNibName:(NSString *)windowNibName;
- (void)dealloc;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (IBAction)login:(id)sender;
- (IBAction)editUsers:(id)sender;
- (IBAction)doneEditing:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)updateUserList;
- (IBAction)newUser:(id)sender;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (IBAction)deleteUser:(id)sender;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation AILoginWindowController
// return an instance of AILoginController
+ (AILoginWindowController *)loginWindowControllerWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner windowNibName:LOGIN_WINDOW_NIB] autorelease]);
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// Internal --------------------------------------------------------------------------------
// init the login controller
- (id)initWithOwner:(id)inOwner windowNibName:(NSString *)windowNibName
{    
    [super initWithWindowNibName:windowNibName];

    //Retain our owner
    owner = [inOwner retain];

    //Get the user list
    [self updateUserList];

    return(self);    
}

// deallocate the login controller
- (void)dealloc
{
    [owner release]; owner = nil;
    [userArray release]; userArray = nil;
    
    [super dealloc];
}

// TableView Delegate methods - Return the number of items in the table
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == tableView_userList){
        return([userArray count]);
    }else if(tableView == tableView_editableUserList){
        return([userArray count]);
    }else{
        return(0);
    }
}

// TableView Delegate methods - Return the requested item in the table
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if(tableView == tableView_userList){
        return([userArray objectAtIndex:row]);
    }else if(tableView == tableView_editableUserList){
        return([userArray objectAtIndex:row]);
    }else{
        return(nil);
    }

}

// Log in with the selected user
- (IBAction)login:(id)sender
{
    NSMutableDictionary	*loginDict;
    NSString 		*selectedUserName = [userArray objectAtIndex:[tableView_userList selectedRow]];

    //Open the login preferences
    loginDict = [NSMutableDictionary dictionaryAtPath:[AIAdium applicationSupportDirectory]
                                         withName:LOGIN_PREFERENCES_FILE_NAME
                                           create:YES];

    //Save the 'display on launch' checkbox state
    [loginDict setObject:[NSNumber numberWithBool:[checkbox_displayOnStartup state]] forKey:LOGIN_SHOW_WINDOW];
    
    //Save the login they used
    [loginDict setObject:selectedUserName forKey:LOGIN_LAST_USER];

    //Save the login preferences
    [loginDict writeToPath:[AIAdium applicationSupportDirectory]
                           withName:LOGIN_PREFERENCES_FILE_NAME];

    //Login
    [owner loginAsUser:selectedUserName];
}

// Display the user list edit sheet
- (IBAction)editUsers:(id)sender
{
    [NSApp beginSheet:panel_userListEditor modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// Close the user list edit sheet
- (IBAction)doneEditing:(id)sender
{
    [NSApp endSheet:panel_userListEditor];
}

// Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Update/Refresh our user list and outline views
- (void)updateUserList
{
    //Update the reference
    [userArray release]; userArray = nil;
    userArray = [[owner userArray] retain];

    //Refresh the tables (if the window is loaded)
    if(tableView_userList != nil && tableView_editableUserList != nil){
        [tableView_userList reloadData];
        [tableView_editableUserList reloadData];
    }
}

// Add a new user
- (IBAction)newUser:(id)sender
{
    int		newRow;

    //Force the table view to end editing
    [tableView_editableUserList reloadData];
    
    //Add a new user
    [owner addUser:NEW_USER_NAME];

    //Refresh our user list and outline views
    [self updateUserList];

    //Select, scroll to, and 'edit' the new user
    newRow = [userArray indexOfObject:NEW_USER_NAME];
    [tableView_editableUserList selectRow:newRow byExtendingSelection:NO];
    [tableView_editableUserList scrollRowToVisible:newRow];
    [tableView_editableUserList editColumn:0 row:newRow withEvent:nil select:YES];
}

// Rename a user
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if(tableView == tableView_editableUserList){
        //Rename the user
        [owner renameUser:[userArray objectAtIndex:row] to:object];

        //Refresh our user list
        [self updateUserList];
    }
}

// Delete the selected user
- (IBAction)deleteUser:(id)sender
{
    //Force the table view to end editing
    [tableView_editableUserList reloadData];

    //Delete the user
    [owner deleteUser:[userArray objectAtIndex:[tableView_editableUserList selectedRow]]];

    //Refresh our user list
    [self updateUserList];
}

// set up the window before it is displayed
- (void)windowDidLoad
{
    NSDictionary	*loginDict;
    NSString		*lastLogin;

    //Open the login preferences
    loginDict = [NSDictionary dictionaryAtPath:[AIAdium applicationSupportDirectory]
                                         withName:LOGIN_PREFERENCES_FILE_NAME
                                           create:YES];

    //Center the window
    [[self window] center];

    //Setup the 'display on launch' checkbox
    [checkbox_displayOnStartup setState:[[loginDict objectForKey:LOGIN_SHOW_WINDOW] boolValue]];

    //Select the login they used last
    lastLogin = [loginDict objectForKey:LOGIN_LAST_USER];
    if(lastLogin != nil && [lastLogin length] != 0 && [userArray indexOfObject:lastLogin] != NSNotFound){
        [tableView_userList selectRow:[userArray indexOfObject:lastLogin] byExtendingSelection:NO];
    }else{
        [tableView_userList selectRow:0 byExtendingSelection:NO];
    }

    //Set login so it's called when the user double clicks a name
    [tableView_userList setDoubleAction:@selector(login:)];

}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    return(YES);
}

@end
