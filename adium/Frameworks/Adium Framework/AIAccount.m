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

// $Id: AIAccount.m,v 1.26 2003/12/26 15:40:10 adamiser Exp $

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
	[self updateStatusForKey:nil];
	
    //Init the account
    [self initAccount];

    return(self);
}

//Dealloc
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [service release];
//    [userIcon release]; userIcon = nil;
    
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
	//Ignore changes directed at another account
	if([notification object] == nil || [notification object] == self){
		NSString    *group = [[notification userInfo] objectForKey:@"Group"];

		//For convenience, we let the account know when a status key for it has changed
		if([group compare:GROUP_ACCOUNT_STATUS] == 0){
			NSString	*key = [[notification userInfo] objectForKey:@"Key"];
			
			[self updateStatusForKey:key];
		}
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

//Update this account's status
//Status keys that are used by every account (Or used by the majority of accounts and harmless to others) should be
//placed here, instead of duplicated in each account plugin.
- (void)updateStatusForKey:(NSString *)key
{
	BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];

    //Online status changed
	//Call connect or disconnect as appropriate
	//
    if([key compare:@"Online"] == 0){
        if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
			if(!areOnline && ![[self statusObjectForKey:@"Connecting"] boolValue]){
				NSLog(@"instructing %@ to connect",[self displayName]);
				//Retrieve the user's password and then call connect
				[[adium accountController] passwordForAccount:self 
											  notifyingTarget:self
													 selector:@selector(passwordReturnedForConnect:)];
			}
        }else{
			if(areOnline && ![[self statusObjectForKey:@"Disconnecting"] boolValue]){
				NSLog(@"instructing %@ to disconnect",[self displayName]);
				//Disconnect
				[self disconnect];
			}
        }
    }

	//Username formatting changed
	//Update the display name for this account
	//
    if(key == nil || [key compare:@"Handle"] == 0){
		[self setStatusObject:[self preferenceForKey:@"Handle" group:GROUP_ACCOUNT_STATUS]
					   forKey:@"Display Name"
					   notify:YES];
    }
	
}

//Callback after the user enters their password for connecting
- (void)passwordReturnedForConnect:(NSString *)inPassword
{
	//If a password was returned, and we're still waiting to connect
	if(inPassword && [inPassword length] != 0 &&
	   ![[self statusObjectForKey:@"Online"] boolValue] &&
	   ![[self statusObjectForKey:@"Connecting"] boolValue]){
        //Save the new password
		if(password != inPassword){
            [password release]; password = [inPassword copy];
        }
		
		//Tell the account to connect
		[self connect];
	}
}


//






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
- (void)connect{};
- (void)disconnect{};
- (NSView *)accountView{return(nil);};
- (NSArray *)supportedPropertyKeys{return([NSArray array]);}









//Auto-Reconnect -------------------------------------------------------------------------------------
//Attempts to auto-reconnect (after an X second delay)
- (void)autoReconnectAfterDelay:(int)delay
{
    //Install a timer to autoreconnect after a delay
    [NSTimer scheduledTimerWithTimeInterval:delay
                                     target:self
                                   selector:@selector(autoReconnectTimer:)
                                   userInfo:nil
                                    repeats:NO];
	
    NSLog(@"Auto-Reconnect in %i seconds",delay);
}

//Perform the auto-reconnect
- (void)autoReconnectTimer:(NSTimer *)inTimer
{
    //If we still want to be online, and we're not yet online, continue with the reconnect
    if([[self preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue] &&
	   ![[self statusObjectForKey:@"Online"] boolValue] && ![[self statusObjectForKey:@"Connecting"] boolValue]){
        NSLog(@"Attempting Auto-Reconnect");
        [self connect];
    }
}


//Update Silencing --------------------------------------------------------------------------------------------
//Silence update for the specified interval
- (void)silenceAllHandleUpdatesForInterval:(NSTimeInterval)interval
{
    silentAndDelayed = YES;
	
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(_endSilenceAllUpdates)
                                   userInfo:nil
                                    repeats:NO];
}

//Stop silencing 
- (void)_endSilenceAllUpdates
{
    silentAndDelayed = NO;
}

@end
