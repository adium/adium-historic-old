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
#include <openssl/md5.h>

@interface MSNAccount (PRIVATE)
- (void)connect;
- (void)disconnect;
@end

@implementation MSNAccount

/*********************/
/* AIAccount_Content */
/*********************/

- (BOOL)sendContentObject:(id <AIContentObject>)object
{
    return NO;
}

- (BOOL)availableForSendingContentType:(NSString *)inType toHandle:(AIHandle *)inHandle
{
    return NO;
}

/*********************/
/* AIAccount_Handles */
/*********************/

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

    socket = [[AISocket socketWithHost:@"messenger.hotmail.com" port:1863] retain];
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
        
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    [inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"INF 1");

    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    [inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);    
    
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
    
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    [inData retain];
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
    [inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"INF 1");

    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    [inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);    
    
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
    
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    [inData retain];
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
    [inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
    /*while(![socket readyForSending]) {}
    [socket sendData:[@"SYN 4 0" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"SYN 4 0");*/
                 
    [self disconnect];

}

- (void)disconnect
{
    [socket release];
}
@end
