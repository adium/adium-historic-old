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

#import "AIDockAccountStatusPlugin.h"

@interface AIDockAccountStatusPlugin (PRIVATE)
- (BOOL)_accountsWithBoolKey:(NSString *)inKey;
- (BOOL)_accountsWithKey:(NSString *)inKey;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_updateIconForKey:(NSString *)key;
@end

@implementation AIDockAccountStatusPlugin

- (void)installPlugin
{
	//Observe account status changes
	[[adium contactController] registerListObjectObserver:self];

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
    
    if(notification == nil || [group isEqualToString:PREF_GROUP_GENERAL]){
		NSString    *key = [[notification userInfo] objectForKey:@"Key"];

		if(notification == nil || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]){
			[self updateListObject:nil keys:nil silent:NO];
		}
    }
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	if(inObject == nil || [inObject isKindOfClass:[AIAccount class]]){
		if(inObject == nil || [inModifiedKeys containsObject:@"Online"]){
			if([self _accountsWithBoolKey:@"Online"] > 0){
				[[adium dockController] setIconStateNamed:@"Online"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Online"];
			}
			
		}
		if(inObject == nil || [inModifiedKeys containsObject:@"Connecting"]){
			if([self _accountsWithBoolKey:@"Connecting"] > 0){
				[[adium dockController] setIconStateNamed:@"Connecting"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Connecting"];
			}
			
		}
		if(inObject == nil || [inModifiedKeys containsObject:@"Away"]){
			if([self _accountsWithBoolKey:@"Away"] > 0){
				[[adium dockController] setIconStateNamed:@"Away"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Away"];
			}
			
		}
		if(inObject == nil || [inModifiedKeys containsObject:@"IdleSince"]){
			if([self _accountsWithKey:@"IdleSince"] > 0){
				[[adium dockController] setIconStateNamed:@"Idle"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Idle"];
			}
			
		}	
	}
	
	return(nil);
}

- (BOOL)_accountsWithBoolKey:(NSString *)inKey
{
    NSEnumerator    *enumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount       *account;
	
    while((account = [enumerator nextObject])){
		if([[account statusObjectForKey:inKey] boolValue]) return(YES);
    }
    
    return(NO);
}

- (BOOL)_accountsWithKey:(NSString *)inKey
{
    NSEnumerator    *enumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount       *account;
	
    while((account = [enumerator nextObject])){
		if([account statusObjectForKey:inKey]) return(YES);
    }
    
    return(NO);
}

@end


