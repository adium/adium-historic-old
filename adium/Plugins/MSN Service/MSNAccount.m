//
//  MSNAccount.m
//  Adium
//
//  Created by Colin Barrett on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MSNAccount.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "MSNStringAdditions.h"
#include <openssl/md5.h>

@interface MSNAccount (PRIVATE)
- (void)connect;
- (void)disconnect;
- (void)syncContactList;
@end

@implementation MSNAccount

/*********************/
/* AIAccount_Content */
/*********************/

- (BOOL)sendContentObject:(AIContentObject *)object
{
    return NO;
}

// Returns YES if the contact is available for receiving content of the specified type
- (BOOL)availableForSendingContentType:(NSString *)inType toChat:(AIChat *)inChat
{
    return NO;
}

- (BOOL)openChat:(AIChat *)inChat
{
    return(NO);
}

- (BOOL)closeChat:(AIChat *)inChat
{
    return(NO);
}


/*********************/
/* AIAccount_Handles */
/*********************/

// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles //return nil if no contacts/list available
{
    int	status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
    
    if(status == STATUS_ONLINE || status == STATUS_CONNECTING)
    {
        return(handleDict);
    }
    else
    {
        return(nil);
    }
}
// Returns YES if the list is editable
- (BOOL)contactListEditable
{
    return NO;
}

// Add a handle to this account
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    return nil;
}
// Remove a handle from this account
- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    return NO;
}

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup
{
    return NO;
}
// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup
{
    return NO;
}
// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    return NO;
}

/********************/
/* AIAccount_Groups */
/********************/

/********************************/
/* AIAccount subclassed methods */
/********************************/

- (void)initAccount
{
    screenName = @"adium2testing@hotmail.com";
    password = @"panther";
    friendlyName = @"Adium 2 Tester";
    
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
}

- (id <AIAccountViewController>)accountView
{
    return nil;
}

- (NSString *)accountID //unique throught the whole app
{
    return [NSString stringWithFormat:@"MSN.%@",screenName];
}

- (NSString *)UID //unique to the service
{
    return screenName;
}

- (NSString *)serviceID //service id
{
    return @"MSN";
}

- (NSString *)UIDAndServiceID //serviceid.uid
{
    return [NSString stringWithFormat:@"%@.%@",[self serviceID],[self UID]];
}

- (NSString *)accountDescription //returns the email addy
{
    return screenName;
}

- (NSArray *)supportedStatusKeys
{
    return([NSArray arrayWithObjects:@"Online", @"Offline", @"Hidden", @"Busy", @"Idle", @"Be Right Back", @"Away", @"On The Phone", @"Out to Lunch", nil]);
}

- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    ACCOUNT_STATUS status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
        
    if([key compare:@"Online"] == 0)
    {
        if([inValue boolValue]) //Connect
        { 
            if(status == STATUS_OFFLINE)
            {
                [self connect];
            }            
        }
        else //Disconnect
        {
            if(status == STATUS_ONLINE)
            {
                [self disconnect];
            }
        }

    }
}

/*******************/
/* Private methods */
/*******************/
- (void)connect
{    
    NSData *inData = nil;
    
    //We are connecting, yay.    
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];

    socket = [[AISocket socketWithHost:@"messenger.hotmail.com" port:1863] retain];
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
        
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    //[inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"INF 1");

    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    //[inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);    
    
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
    
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    //[inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    NSArray *hostAndPort = [[[[NSString stringWithCString:[inData bytes] length:[inData length]] 
        componentsSeparatedByString:@" "]
            objectAtIndex:3] componentsSeparatedByString:@":"];
            
    [socket release];
    socket = [[AISocket 
            socketWithHost:[hostAndPort objectAtIndex:0]
            port:[[hostAndPort objectAtIndex:1] intValue]]
        retain];
        
    while(![socket readyForSending]) {}
    [socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
        
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"INF 1");

    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);    
    
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
    
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    NSData *tempData = [[NSString stringWithFormat:@"%@%@",
            [[[NSString stringWithCString:[inData bytes] length:[inData length]-2] 					componentsSeparatedByString:@" "] objectAtIndex:4], 
            password]
            dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSData *mdData = [NSData dataWithBytes:(const int *)MD5([tempData bytes],
            [tempData length], NULL) length:16];
        
    NSString *sendStr = [mdData description];
    sendStr = [sendStr substringWithRange:NSMakeRange(1,[sendStr length]-2)];
    sendStr = [sendStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    sendStr = [[sendStr componentsSeparatedByString:@" "] componentsJoinedByString:@""];
                                                        
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 3 MD5 S %@\r\n", sendStr] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 3 MD5 S %@", sendStr]);
    
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
            
    [self syncContactList];
    
    //We are connected, yay.
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:self];
    
}

- (void)disconnect
{
    [socket release];
}

- (void)syncContactList
{
    NSData *inData = nil;
    BOOL oneShot = YES;

    while(![socket readyForReceiving]) {}
    while([socket readyForReceiving])
    {
        [socket getDataToNewline:&inData];
        NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
        NSArray *message = [[NSString stringWithCString:[inData bytes] length:[inData length]] componentsSeparatedByString:@" "];
        
        if([[message objectAtIndex:0] isEqual:@"LST"]) //this is a person
        {
            if([[message objectAtIndex:2] isEqual:@"FL"])
            {
                [handleDict setObject:
                    [AIHandle handleWithServiceID:[[service handleServiceType] identifier]
                        UID:[message objectAtIndex:6]
                        serverGroup:@"MSN"
                        temporary:NO
                        forAccount:self]
                forKey:[[message objectAtIndex:7] urlDecode]];
            }
        }
        else if([[message objectAtIndex:0] isEqual:@"MSG"]) //this is some kind of message from the server
        {
            NSLog(@"%d",[[message objectAtIndex:3] intValue]);
            while(![socket readyForReceiving]) {}
            [socket getData:&inData ofLength:[[message objectAtIndex:3] intValue]];
            NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
            
            //now we send out our SYN, only the first time, though.
            if(oneShot)
            {
                while(![socket readyForSending]) {}
                [socket sendData:[@"SYN 4 0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                NSLog(@">>> %@", @"SYN 4 0");
                oneShot = NO;
            }
        }
        
        //this is how we know we're done. when we get the last message of the reverse list.
        if([[message objectAtIndex:0] isEqual:@"LST"]
        && [[message objectAtIndex:2] isEqual:@"RL"] 
        && [[message objectAtIndex:4] isEqual:[message objectAtIndex:5]])
        {
            NSLog(@"done");
            return;
        }
                
        while(![socket readyForReceiving]) {}
    }
}

@end
