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

// $Id: AIAccount.m,v 1.19 2003/12/24 01:30:18 adamiser Exp $

#import "AIAccount.h"

@interface AIAccount (PRIVATE)
@end

@implementation AIAccount

//-------------------
//  Public Methods
//-----------------------
//Init the connection
- (id)initWithUID:(NSString *)inUID service:(id <AIServiceController>)inService
{
    [super initWithUID:inUID serviceID:[[inService handleServiceType] identifier]];

    //Get our service
    service = [inService retain];
    changedStatusKeys = [[NSMutableArray alloc] init];

    //Handle the preference changed monitoring (for account status) for our subclass
    [[adium notificationCenter] addObserver:self
								   selector:@selector(_accountPreferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    
    //Clear the online state.  'Auto-Connect' values are used, not the previous online state.
    [self setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];

    //Init the account
    [self initAccount];

    return(self);
}

//Dealloc
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [service release];
    [userIcon release]; userIcon = nil;
    
    [super dealloc];
}

//Return the service that spawned this account
- (id <AIServiceController>)service
{
    return(service);
}

//Store our account prefs in a separate folder to keep things clean
- (NSString *)pathToPreferences
{
    return([[[adium loginController] userDirectory] stringByAppendingPathComponent:ACCOUNT_PREFS_PATH]);
}

//Monitor preferences changed for account status keys, and pass these to our subclass
- (void)_accountPreferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    if([group compare:GROUP_ACCOUNT_STATUS] == 0){
		NSString	*key = [[notification userInfo] objectForKey:@"Key"];
		
		[self updateStatusForKey:key];
    }
}

//Quickly set a status key for this account
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify
{
    [[self statusArrayForKey:key] setObject:value withOwner:self];
    [changedStatusKeys addObject:key];
    
    if(notify){
		[[adium contactController] listObjectStatusChanged:self modifiedStatusKeys:changedStatusKeys delayed:NO silent:NO];
		[changedStatusKeys release]; changedStatusKeys = [[NSMutableArray alloc] init];
    }
}

//Quickly retrieve a status key for this account
- (id)statusObjectForKey:(NSString *)key
{
    return([[self statusArrayForKey:key] objectWithOwner:self]);
}

//Return the account-specific user icon, or the default user icon from the account controlelr if none exists (thee default user icon returns nil if none is set)
//- (NSImage *)userIcon {
//    if (userIcon)
//        return userIcon;
//    else
//        return [[adium accountController] defaultUserIcon];
//}
//
//- (void)setUserIcon:(NSImage *)inUserIcon {
//    [userIcon release];
//    userIcon = [inUserIcon retain];
//}

//Functions for subclasses to override
- (void)initAccount{};
- (NSView *)accountView{return(nil);};
- (void)updateStatusForKey:(NSString *)key{};
- (NSArray *)supportedPropertyKeys{return([NSArray array]);}

@end
