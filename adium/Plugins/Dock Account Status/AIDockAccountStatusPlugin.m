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
- (void)accountPropertiesChanged:(NSNotification *)notification;
@end

@implementation AIDockAccountStatusPlugin

- (void)installPlugin
{
    //Observe account status changed notification
    [[adium notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged object:nil];

    //Observer preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self accountPropertiesChanged:nil];
}

- (void)uninstallPlugin
{
    //Remove observers (general)
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)accountListChanged:(NSNotification *)notification
{
    [self accountPropertiesChanged:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if( ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0) && ([(NSString *)[[notification userInfo] objectForKey:@"Key"] compare:KEY_ACTIVE_DOCK_ICON] == 0) )
    {
        [self accountPropertiesChanged:nil];
    }
}

- (void)accountPropertiesChanged:(NSNotification *)notification
{
    NSString	*key = [[notification userInfo] objectForKey:@"Key"];
    AIAccount	*changedAccount = [notification object];
    if(notification == nil || [key compare:@"Status"] == 0){ //Account status changed
        NSEnumerator	*enumerator;
        AIAccount		*account;
        int			onlineAccounts = 0;
        int			connectingAccounts = 0;

        enumerator = [[[adium accountController] accountArray] objectEnumerator];
        while((account = [enumerator nextObject])){
            int status = [[account propertyForKey:@"Status"] intValue];

            if(status == STATUS_ONLINE){
                onlineAccounts++;
            }else if(status == STATUS_CONNECTING){
                connectingAccounts++;
            }
        }
        //Online
        if(onlineAccounts || notification == nil){
            [[adium dockController] setIconStateNamed:@"Online"];
        }else{
            [[adium dockController] removeIconStateNamed:@"Online"];
        }

        //Connecting
        if(connectingAccounts){
            [[adium dockController] setIconStateNamed:@"Connecting"];
        }else{
            [[adium dockController] removeIconStateNamed:@"Connecting"];
        }

    }

    if(notification == nil || [key compare:@"AwayMessage"] == 0){
        if(changedAccount == nil){ //Global status change
            BOOL away = ([[adium accountController] propertyForKey:@"AwayMessage" account:nil] != nil);

            if(away){
                [[adium dockController] setIconStateNamed:@"Away"];
            }else{
                [[adium dockController] removeIconStateNamed:@"Away"];
            }

        }

    }
    
    if(notification == nil || [key compare:@"IdleSince"] == 0){
        if(changedAccount == nil){ //Global status change
            BOOL idle = ([[adium accountController] propertyForKey:@"IdleSince" account:nil] != nil);

            if(idle){
                [[adium dockController] setIconStateNamed:@"Idle"];
            }else{
                [[adium dockController] removeIconStateNamed:@"Idle"];
            }

        }

    }
}

@end


