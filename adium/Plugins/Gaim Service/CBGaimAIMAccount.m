//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimAIMAccount.h"

#warning change this to your SN to connect :-)
#define SCREEN_NAME "otsku"
#define PROTOCOL "prpl-oscar"

@implementation CBGaimAIMAccount

- (NSArray *)supportedPropertyKeys
{
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[super supportedPropertyKeys]];
    [arr addObject:@"Away"];
    return arr;
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    NSLog(@"gaim: statusForKey: %@ willChangeTo: %@", key, inValue);
    ACCOUNT_STATUS status = [[[owner accountController] propertyForKey:@"Status" account:self] intValue];
        
    if([key compare:@"Online"] == 0)
    {
        if([inValue boolValue]) //Connect
        { 
            if(status == STATUS_OFFLINE)
            {                
                //get password
                [[owner accountController] passwordForAccount:self 
                    notifyingTarget:self selector:@selector(finishConnect:)];
            }
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                //we're signing off, give us a minute.
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_DISCONNECTING]
                    forKey:@"Status" account:self];
                
                //delete the account, sign everybody off
                GaimAccount *account;
                if(account = gaim_accounts_find(SCREEN_NAME, PROTOCOL))
                {
                    gaim_account_disconnect(account);
                    gaim_accounts_delete(account);
                }
                
                //done
                [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
                    forKey:@"Status" account:self];
            }
        }
    }
}

- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0)
    {
        //now we start to connect
        [[owner accountController] 
            setProperty:[NSNumber numberWithInt:STATUS_CONNECTING]
            forKey:@"Status" account:self];

        //setup the account, get things ready
        GaimAccount *testAccount = gaim_account_new(SCREEN_NAME, PROTOCOL);
        gaim_account_set_password(testAccount, [inPassword cString]);
        
        //this is a bit of a hack, but it will do for now
        GaimConnection *conn =  gaim_account_connect(testAccount);
        if(gaim_connection_get_state(conn) != GAIM_DISCONNECTED) //if we're not disconneted, signed on!
        {
            gaim_accounts_add(testAccount);
            
            [[owner accountController]
                setProperty:[NSNumber numberWithInt:STATUS_ONLINE]
                forKey:@"Status" account:self];
        }
        else //aw nuts, something must have happened.
        {
            [[owner accountController] 
                    setProperty:[NSNumber numberWithInt:STATUS_OFFLINE]
                    forKey:@"Status" account:self];
        }
    }
}

- (NSString *)accountID{
    return([NSString stringWithFormat:@"%s.%s", "AIM", SCREEN_NAME]);
}

- (NSString *)UID{
    return([NSString stringWithUTF8String:SCREEN_NAME]);
}
    
- (NSString *)serviceID{
    return([NSString stringWithUTF8String:"AIM"]);
}

- (NSString *)UIDAndServiceID{
    return([NSString stringWithFormat:@"%s.%s", "AIM", SCREEN_NAME]);
}

- (NSString *)accountDescription
{
    return [self UIDAndServiceID];
}

@end
