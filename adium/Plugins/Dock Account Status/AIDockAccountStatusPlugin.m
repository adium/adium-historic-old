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

#import "AIDockAccountStatusPlugin.h"

@interface AIDockAccountStatusPlugin (PRIVATE)
- (int)_numberOfAccountsWithBoolKey:(NSString *)inKey;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_updateIconForKey:(NSString *)key;
@end

@implementation AIDockAccountStatusPlugin

- (void)installPlugin
{
    //Observer preference changes
    [[adium notificationCenter] addObserver:self
				   selector:@selector(preferencesChanged:)
				       name:Preference_GroupChanged
				     object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //Remove observers (general)
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)preferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    NSString    *key = [[notification userInfo] objectForKey:@"Key"];
    
    if(notification == nil || ([group compare:PREF_GROUP_GENERAL] == 0 && [key compare:KEY_ACTIVE_DOCK_ICON] == 0)){
	[self _updateIconForKey:nil];
	
    }else if([group compare:GROUP_ACCOUNT_STATUS] == 0){
	[self _updateIconForKey:key];
    }
}

- (void)_updateIconForKey:(NSString *)key
{
    if(key == nil || [key compare:@"Online"] == 0){
	if([self _numberOfAccountsWithBoolKey:@"Online"] > 0){
	    [[adium dockController] setIconStateNamed:@"Online"];
	}else{
	    [[adium dockController] removeIconStateNamed:@"Online"];
	}
	
    }else if(key == nil || [key compare:@"Connecting"] == 0){
	if([self _numberOfAccountsWithBoolKey:@"Connecting"] > 0){
	    [[adium dockController] setIconStateNamed:@"Connecting"];
	}else{
	    [[adium dockController] removeIconStateNamed:@"Connecting"];
	}
	
    }else if(key == nil || [key compare:@"AwayMessage"] == 0){	    
	if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] != nil){
	    [[adium dockController] setIconStateNamed:@"Away"];
	}else{
	    [[adium dockController] removeIconStateNamed:@"Away"];
	}
	
    }else if(key == nil || [key compare:@"IdleSince"] == 0){
	if([[adium preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] != nil){
	    [[adium dockController] setIconStateNamed:@"Idle"];
	}else{
	    [[adium dockController] removeIconStateNamed:@"Idle"];
	}
	
    }	
}

- (int)_numberOfAccountsWithBoolKey:(NSString *)inKey
{
    NSEnumerator    *enumerator = [[[adium accountController] accountArray] objectEnumerator];
    int		    onlineAccounts = 0;
    AIAccount       *account;

    while((account = [enumerator nextObject])){
	if([[account statusObjectForKey:inKey] boolValue]) onlineAccounts++;
    }
    
    return(onlineAccounts);
}

@end


