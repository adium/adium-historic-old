//
//  AIDockAccountStatusPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Apr 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDockAccountStatusPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>


@implementation AIDockAccountStatusPlugin

- (void)installPlugin
{
    //Init
    onlineState = nil;
    awayState = nil;
    idleState = nil;
    connectingState = nil;
    
    //Observe account status changed notification
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];
}

- (void)uninstallPlugin
{

}

- (void)accountStatusChanged:(NSNotification *)notification
{
    NSString	*key = [[notification userInfo] objectForKey:@"Key"];
    AIAccount	*changedAccount = [notification object];

    if(key){
        if([key compare:@"Status"] == 0){ //Account status changed
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
            if(onlineAccounts && !onlineState){
                onlineState = [[owner dockController] setIconStateNamed:@"Online"];
            }else if(!onlineAccounts && onlineState){
                [[owner dockController] removeIconState:onlineState]; onlineState = nil;
            }

            //Connecting
            if(connectingAccounts && !connectingState){
                connectingState = [[owner dockController] setIconStateNamed:@"Connecting"];
            }else if(!connectingAccounts && connectingState){
                [[owner dockController] removeIconState:connectingState]; connectingState = nil;
            }

        }else if([key compare:@"AwayMessage"] == 0){
            if(changedAccount == nil){ //Global status change
                BOOL away = ([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil);

                if(away && !awayState){
                    awayState = [[owner dockController] setIconStateNamed:@"Away"];
                }else if(!away && awayState){
                    [[owner dockController] removeIconState:awayState]; awayState = nil;
                }

            }

        }else if([key compare:@"IdleSince"] == 0){
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
}

@end


