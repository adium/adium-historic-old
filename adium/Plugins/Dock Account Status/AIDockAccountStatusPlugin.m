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
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>


@interface AIDockAccountStatusPlugin (PRIVATE)
- (void)accountStatusChanged:(NSNotification *)notification;
@end

@implementation AIDockAccountStatusPlugin

- (void)installPlugin
{
    //Init
    onlineState = nil;
    awayState = nil;
    idleState = nil;
    connectingState = nil;

    //Observe account status changed notification
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self accountStatusChanged:nil];
}

- (void)uninstallPlugin
{
    //Remove observers (general)
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)accountListChanged:(NSNotification *)notification
{
    [self accountStatusChanged:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if( ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0) && ([(NSString *)[[notification userInfo] objectForKey:@"Key"] compare:KEY_ACTIVE_DOCK_ICON] == 0) )
    {
        [self accountStatusChanged:nil];
    }
}

- (void)accountStatusChanged:(NSNotification *)notification
{
    NSString	*key = [[notification userInfo] objectForKey:@"Key"];
    AIAccount	*changedAccount = [notification object];
    if(notification == nil || [key compare:@"Status"] == 0){ //Account status changed
        NSEnumerator	*enumerator;
        AIAccount		*account;
        int			onlineAccounts = 0;
        int			connectingAccounts = 0;

        enumerator = [[[owner accountController] accountArray] objectEnumerator];
        while((account = [enumerator nextObject])){
            int status = [[account statusObjectForKey:@"Status"] intValue];

            if(status == STATUS_ONLINE){
                onlineAccounts++;
            }else if(status == STATUS_CONNECTING){
                connectingAccounts++;
            }
        }
        //Online
        if(onlineAccounts && (notification == nil || !onlineState)) {            onlineState = [[owner dockController] setIconStateNamed:@"Online"];
        }else if(!onlineAccounts && onlineState){
            [[owner dockController] removeIconState:onlineState]; onlineState = nil;
        }

        //Connecting
        if(connectingAccounts && !connectingState){
            connectingState = [[owner dockController] setIconStateNamed:@"Connecting"];
        }else if(!connectingAccounts && connectingState){
            [[owner dockController] removeIconState:connectingState]; connectingState = nil;
        }

    }

    if(notification == nil || [key compare:@"AwayMessage"] == 0){
        if(changedAccount == nil){ //Global status change
            BOOL away = ([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil);

            if(away && !awayState){
                awayState = [[owner dockController] setIconStateNamed:@"Away"];
            }else if(!away && awayState){
                [[owner dockController] removeIconState:awayState]; awayState = nil;
            }

        }

    }

    if(notification == nil || [key compare:@"IdleSince"] == 0){
        if(changedAccount == nil){ //Global status change
            BOOL idle = ([[owner accountController] statusObjectForKey:@"IdleSince" account:nil] != nil);

            if(idle && !idleState){
                idleState = [[owner dockController] setIconStateNamed:@"Idle"];

            }else if(!idle && idleState){
                [[owner dockController] removeIconState:idleState];
                idleState = nil;

            }

        }

    }
}

@end


