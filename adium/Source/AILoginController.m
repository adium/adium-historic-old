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

// $Id: AILoginController.m,v 1.13 2004/05/24 06:04:04 evands Exp $

#import "AILoginController.h"
#import "AILoginWindowController.h"

//Paths & Filenames
#define PATH_USERS 			@"/Users"		//Path of the users folder
#define PATH_TRASH			@"~/.Trash"		//Path to the trash
//Other
#define DEFAULT_USER_NAME		@"Default"		//The default user name

@implementation AILoginController

// Init this controller
- (void)initController
{
    userDirectory = nil;
}

// Close this controller
- (void)closeController
{

}

// Dealloc
- (void)dealloc
{
    [userDirectory release];
    [currentUser release];

    [super dealloc];
}

// Prompts for a user, or automatically selects one
- (void)requestUserNotifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    NSMutableDictionary	*loginDict;

    //Retain the target and selector
    target = inTarget;
    selector = inSelector;

    //Open the login preferences
    loginDict = [NSMutableDictionary dictionaryAtPath:[AIAdium applicationSupportDirectory] withName:LOGIN_PREFERENCES_FILE_NAME create:YES];

    //Make sure that atleast 1 login name is available.  If not, create the name 'default'
    if([[self userArray] count] == 0){
        //Create a 'default' user
        [self addUser:DEFAULT_USER_NAME];

        //Set 'default' as the login of choice
        [loginDict setObject:DEFAULT_USER_NAME forKey:LOGIN_LAST_USER];
		[loginDict writeToPath:[AIAdium applicationSupportDirectory] withName:LOGIN_PREFERENCES_FILE_NAME];
    }

    //Show the login select window?
    if([NSEvent optionKey] || [[loginDict objectForKey:LOGIN_SHOW_WINDOW] boolValue] || [loginDict objectForKey:LOGIN_LAST_USER] == nil){

        //Prompt for the user
        loginWindowController = [[AILoginWindowController loginWindowControllerWithOwner:self] retain];
        [loginWindowController showWindow:nil];

    }else{
        //Auto-login as the saved user
        [self loginAsUser:[loginDict objectForKey:LOGIN_LAST_USER]];
    }
}

// Returns the current user's Adium home directory
- (NSString *)userDirectory
{
    return(userDirectory);
}

//
- (NSString *)currentUser
{
    return(currentUser);
}

// Sets the correct user directory and sends out a login message
- (void)loginAsUser:(NSString *)userName
{
    NSParameterAssert(userName != nil);
    
    //Close the login panel
    if(loginWindowController){
        [loginWindowController closeWindow:nil];
        [loginWindowController release]; loginWindowController = nil;
    }

    //Save the user directory
    currentUser = [userName copy];
    userDirectory = [[[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:userName] retain];
    
    //Tell Adium to complete login
    [target performSelector:selector];
}

// Switches users: logs out, provides user choosing dialog
- (void)switchUsers
{
    // Log out previous user
    [target applicationWillTerminate:nil];
    
    // Open login panel
    loginWindowController = [[AILoginWindowController loginWindowControllerWithOwner:self] retain];
    [loginWindowController showWindow:nil];
}

// Creates and returns a mutable array of the login users
- (NSArray *)userArray
{
    NSString		*userPath;
    NSArray		*directoryContents;
    NSMutableArray	*userArray;
    int			loop;
    BOOL		isDirectory;

    //Get the users path
    userPath = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS];

    //Build the user array
    userArray = [[NSMutableArray alloc] init];

    directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:userPath];
    for(loop = 0;loop < [directoryContents count];loop++){
        NSString	*path = [directoryContents objectAtIndex:loop];

        //Fetch the names of all directories
        if([[NSFileManager defaultManager] fileExistsAtPath:[userPath stringByAppendingPathComponent:path] isDirectory:&isDirectory]){
            if(isDirectory){
                [userArray addObject:[path lastPathComponent]];
            }
        }
    }

    return([userArray autorelease]);
}

// Delete a user
- (void)deleteUser:(NSString *)inUserName
{
    NSString	*sourcePath;

    NSParameterAssert(inUserName != nil);

    //Create the source and dest paths	
    sourcePath = [[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:inUserName];
	[[NSFileManager defaultManager] trashFileAtPath:sourcePath];
}

// Add a user with the specified name
- (void)addUser:(NSString *)inUserName
{
    NSString	*userPath;
    
    NSParameterAssert(inUserName != nil);

    //Create the user path
    userPath = [[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:inUserName];
    
    //Create a folder for the new user
    [[NSFileManager defaultManager] createDirectoriesForPath:userPath];
}

// Rename an existing user
- (void)renameUser:(NSString *)oldName to:(NSString *)newName
{
    NSString	*sourcePath, *destPath;

    NSParameterAssert(oldName != nil);
    NSParameterAssert(newName != nil);

    //Create the source and dest paths
    sourcePath = [[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:oldName];
    destPath = [[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:newName];

    //Rename the user's folder (by moving it to a path with a different name)
    [[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil];
}

@end

