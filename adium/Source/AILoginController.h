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

#define LOGIN_PREFERENCES_FILE_NAME @"Login Preferences"	//Login preferences file name
#define LOGIN_SHOW_WINDOW 			@"Show Login Window"	//Should hide the login window 
#define LOGIN_LAST_USER				@"Last Login Name"		//Last logged in user

@class AILoginWindowController;

@interface AILoginController : NSObject{
    IBOutlet	AIAdium			*owner;
    
    NSString					*currentUser;			//The current logged in username
    NSString					*userDirectory;			//The current user's Adium home directory
    AILoginWindowController		*loginWindowController;	//The login select window
    id							target;					//Used to send our owner a 'login complete'
    SEL							selector;				//
}

- (NSString *)userDirectory;
- (NSString *)currentUser;
- (void)switchUsers;

//Private
- (void)initController;
- (void)closeController;
- (void)requestUserNotifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (NSArray *)userArray;
- (void)deleteUser:(NSString *)inUserName;
- (void)addUser:(NSString *)inUserName;
- (void)renameUser:(NSString *)oldName to:(NSString *)newName;
- (void)loginAsUser:(NSString *)userName;

@end
