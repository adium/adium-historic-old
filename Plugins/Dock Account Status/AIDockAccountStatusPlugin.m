/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
}

- (void)uninstallPlugin
{
    //Remove observers (general)
	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(!key || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]){
		[self updateListObject:nil keys:nil silent:NO];
	}
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
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


