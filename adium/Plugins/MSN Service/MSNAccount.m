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

#define TIMES_PER_SECOND 20.0
#define MAX_CONNECTION_PHASE	22

@interface MSNAccount (PRIVATE)
- (void)startConnect;
- (void)connect:(NSTimer *)timer;
- (void)update:(NSTimer *)timer;
- (void)disconnect;
//- (void)syncContactList;
//- (void)receiveInitialStatus;
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
    
    handleDict = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
    [handleDict release];
    
    [super dealloc];
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
                [self startConnect];
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

- (void)startConnect
{
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];
    
    connectionPhase = 1;
    
    stepTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/TIMES_PER_SECOND
        target:self
        selector:@selector(update:)
        userInfo:[[NSMutableDictionary alloc] initWithObjectsAndKeys:
            @"", @"String",
            [NSNumber numberWithInt:0], @"Number",
            nil]
        repeats:YES];
}

- (void)connect:(NSTimer *)timer
{
    NSData *inData = nil;
    if ([socket isValid] || socket == nil)
    {
        switch (connectionPhase)
        {
            case 1:
                socket = [[AISocket socketWithHost:@"messenger.hotmail.com" port:1863] retain];
                connectionPhase ++;
                break;
                    
            case 2:
                if ([socket readyForSending])
                {
                    [socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
                    connectionPhase ++;
                }
                break;
            
            case 3:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    connectionPhase ++;
                }
                break;
                    
            case 4:
                if ([socket readyForSending])
                {
                    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"INF 1");
                    connectionPhase ++;
                }
                break;
            
            case 5:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]); 
                    
                    connectionPhase ++;
                }
                break;
                    
            case 6:
                if ([socket readyForSending])
                {
                    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",
                        [screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",
                        [screenName cString]]);
                    connectionPhase ++;
                }
                break;
            
            case 7:
                if ([socket readyForReceiving])
                {	
                    // In this phase, we receive data concerning the next server to connect to, 
                    // and then we connect.
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]);
                    
                    NSArray *hostAndPort = [[[[NSString stringWithCString:[inData bytes]
                        length:[inData length]] 
                            componentsSeparatedByString:@" "]
                                    objectAtIndex:3] componentsSeparatedByString:@":"];
                                    
                    [socket release];
                    socket = [[AISocket 
                                    socketWithHost:[hostAndPort objectAtIndex:0]
                                    port:[[hostAndPort objectAtIndex:1] intValue]]
                            retain];
                    connectionPhase ++;
                }
                break;
                    
            case 8:
                if ([socket readyForSending])
                {
                    [socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
                    connectionPhase ++;
                }
                break;
            
            case 9:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]);
                    connectionPhase ++;
                }
                break;
                    
            case 10:
                if ([socket readyForSending])
                {
                    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"INF 1");
                    connectionPhase ++;
                }
                break;
            
            case 11:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]); 
                    
                    connectionPhase ++;
                }
                break;
                    
            case 12:
                if ([socket readyForSending])
                {
                    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",
                        [screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",
                        [screenName cString]]);
                    connectionPhase ++;
                }
                break;
            
            case 13:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    
                    // Use the info passed by the server to produce a properly encrypted password
                    NSData *tempData = [[NSString stringWithFormat:@"%@%@",
                        [[[NSString stringWithCString:[inData bytes] length:[inData length]-2] 						componentsSeparatedByString:@" "] objectAtIndex:4], 
                            password]
                        dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                    
                    NSData *mdData = [NSData dataWithBytes:(const int *)MD5([tempData bytes],
                                    [tempData length], NULL) length:16];
                            
                    NSString *temp = [mdData description];
                    temp = [temp substringWithRange:NSMakeRange(1,[temp length]-2)];
                    temp = [temp stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceCharacterSet]];
                    temp = [[temp componentsSeparatedByString:@" "] componentsJoinedByString:@""];
                    
                    NSLog (@"Password encrypted");
                    
                    [[timer userInfo] setObject:temp forKey:@"String"];
                    connectionPhase ++;
                }
                break;
                    
            case 14:
                if ([socket readyForSending])
                {
                    NSString *temp = [[timer userInfo] objectForKey:@"String"];
                    NSLog (@"Password being sent");
                    [socket sendData:[[NSString stringWithFormat:@"USR 3 MD5 S %@\r\n", temp]
                        dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 3 MD5 S %@", temp]);
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    connectionPhase ++;
                }
                break;
            
            case 15:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]); 
                    
                    connectionPhase ++;
                }
                break;
                    
            // Contact List Update	//
            case 16:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    NSArray *message = [[NSString stringWithCString:[inData bytes] 
                        length:[inData length]] 
                    componentsSeparatedByString:@" "];
                    
                    //this is some kind of message from the server
                    if([[message objectAtIndex:0] isEqual:@"MSG"]) 
                    {
                        NSLog(@"%d",[[message objectAtIndex:3] intValue]);
                        [[timer userInfo] setObject:[message objectAtIndex:3] forKey:@"String"];
                        connectionPhase++;
                    }
                }
                break;
            
            case 17:
                if ([socket readyForReceiving])
                {
                    [socket getData:&inData ofLength:
                        [[[timer userInfo] objectForKey:@"String"] intValue]];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    connectionPhase++;
                }
                break;
            
            case 18:
                //now we send out our SYN
                if ([socket readyForSending])
                {
                    [socket sendData:[@"SYN 4 0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"SYN 4 0");
                    connectionPhase++;
                }
                break;
                    
            case 19:
                if ([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    NSArray *message = [[NSString stringWithCString:[inData bytes] 
                        length:[inData length]] componentsSeparatedByString:@" "];
                    
                    if([[message objectAtIndex:0] isEqual:@"LST"]) //this is a person
                    {
                        if([[message objectAtIndex:2] isEqual:@"FL"])
                        {
                            AIHandle *theHandle = [AIHandle 
                                    handleWithServiceID:[[service handleServiceType] identifier]
                                    UID:[message objectAtIndex:6]
                                    serverGroup:@"MSN"
                                    temporary:NO
                                    forAccount:self];                                                
                            [handleDict setObject:theHandle forKey:[message objectAtIndex:6]];
                            
                            [[owner contactController] handle:theHandle addedToAccount:self];
                        }
                        else if([[message objectAtIndex:2] isEqual:@"RL"])
                        {
                            //this is how we know we're done. when we get the last message of the reverse list.
                            if([[message objectAtIndex:4] isEqual:[message objectAtIndex:5]])
                            {
                                NSLog(@"done");
                                connectionPhase++;
                            }
                        }
                    }
                    else if([[message objectAtIndex:0] isEqual:@"MSG"]) //this is some kind of message from the server
                    {
                        NSLog(@"%d",[[message objectAtIndex:3] intValue]);
                        while(![socket readyForReceiving]) {}
                        [socket getData:&inData ofLength:[[message objectAtIndex:3] intValue]];
                        NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                            length:[inData length]]);
                    }
                }
                break;
                
            case 20:
                if([socket readyForSending])
                {
                    [socket sendData:[@"CHG 5 NLN\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"CHG 5 NLN");			
                    connectionPhase ++;
                }
                break;
            
            case 21:
                if([socket readyForSending])
                {
                    //send a PNG so we know when we are done (when we get the QNG)
                    [socket sendData:[@"PNG\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", @"PNG");
                    connectionPhase ++;
                }
                break;
            case 22:
                if([socket readyForReceiving])
                {
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    
                    if([[NSString stringWithCString:[inData bytes] length:[inData length]]
                        isEqual:@"QNG\r\n"])
                    {
                        connectionPhase ++;
                    }
                    
                    NSArray *message = [[NSString stringWithCString:[inData bytes] 
                        length:[inData length]] componentsSeparatedByString:@" "];
                    
                    if([[message objectAtIndex:0] isEqual:@"ILN"]) //this is a person
                    {
                        AIHandle *theHandle = [handleDict objectForKey:[message objectAtIndex:3]];
                        
                        [[theHandle statusDictionary]
                            setObject:[NSNumber numberWithInt:1]
                            forKey:@"Online"];
                        
                        NSLog(@"%@",[[[message objectAtIndex:4] 
                                stringByTrimmingCharactersInSet:
                                    [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]]
                                        urlDecode]);
                        
                        [[theHandle statusDictionary]
                            setObject:[[[message objectAtIndex:4] 
                                stringByTrimmingCharactersInSet:
                                    [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]]
                                        urlDecode]
                            forKey:@"Display Name"];
                            
                        [[owner contactController] handleStatusChanged:theHandle
                            modifiedStatusKeys:
                                [NSArray arrayWithObjects:@"Online", @"Display Name"]];
            
                    }
                }
                break;
                    
            default:
                [[owner accountController] 
                    setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE]
                        forKey:@"Status" account:self];
                break;
        }
    }
    else
    {
        NSLog (@"Socket found to be invalid");
        
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] 			forKey:@"Status" account:self];
    }
}

- (void)getPackets:(NSTimer *)timer
{
    /*NSData *inData = nil; //don't want old data hanving around
    if ([socket isValid])
    {
        switch([[[timer userInfo] objectForKey:@"Number"] intValue])
        {
            case 0: //read
                if([socket readyForReceiving])
                {
                    //get the data, put it into message.
                    [socket getDataToNewline:&inData];
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    NSArray *message = [[NSString stringWithCString:[inData bytes] 
                        length:[inData length]-2] 
                    componentsSeparatedByString:@" "];
                    
                    //just convenience
                    NSString *command = [message objectAtIndex:0];
                    
                    if([command isEqual:@"CHL"])
                    {
                        //create the data
                        NSData *tempData = [[NSString stringWithFormat:@"%@Q1P7W2E4J9R8U3S5",
                                [message objectAtIndex:2]]
                            dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                        
                        //md5 it
                        NSData *mdData = [NSData dataWithBytes:(const int *)MD5([tempData bytes],
                                        [tempData length], NULL) length:16];
                        
                        //do stuff to get the number right
                        NSString *temp = [mdData description];
                        temp = [temp substringWithRange:NSMakeRange(1,[temp length]-2)];
                        temp = [temp stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceCharacterSet]];
                        temp = [[temp componentsSeparatedByString:@" "]
                            componentsJoinedByString:@""];
                        
                        //set it in userInfo
                        [[timer userInfo] setObject:temp forKey:@"String"];
                        
                        //go to sending stage
                        [[timer userInfo] setObject:[NSNumber numberWithInt:1] forKey:@"Number"];
                    }
                    else if([command isEqual:@""])
                    {
                        //do stuff...
                    }
                }
                break;
                
            case 1: //Send
                if([socket readyForSending])
                {
                    //send it out
                    [socket sendData:[[[timer userInfo] objectForKey:@"String"]
                        dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@">>> %@", [[timer userInfo] objectForKey:@"String"]);
                    
                    //reset the string
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    
                    //go back to reading
                    [[timer userInfo] setObject:[NSNumber numberWithInt:0] forKey:@"Number"];
                    
                }
                break;
                
            case 2: //Receive a payload command, the length is in String. 
                    //Afterward, the data will be in String, AS AN NSDATA. BE CAREFUL
                if([socket readyForReceiving])
                {
                    //get the length
                    int length = [[[timer userInfo] objectForKey:@"String"] intValue];
                    
                    //if we don't have temp, create it
                    if([[timer userInfo] objectForKey:@"temp"] == nil)
                    {
                        [[timer userInfo] setObject:[[NSMutableData alloc] init] forKey:@"temp"];
                    }
                    
                    //Get data, then check if we don't have all the data
                    if(![socket getData:&inData ofLength:length])
                    {
                        //put the data in temp.
                        [[[timer userInfo] objectForKey:@"temp"] appendData:inData];
                    }
                    else //if we do have all the data
                    {
                        //put the data in String.
                        [[[timer userInfo] objectForKey:@"temp"] appendData:inData];
                        
                        //put the final data into String.
                        [[timer userInfo] setObject:[[timer userInfo] objectForKey:@"temp"]
                            forKey:@"String"];
                        
                        //remove temp
                        [[timer userInfo] removeObjectForKey:@"temp"];
                        
                        //go back to reading packets, we are done here.
                        [[timer userInfo] setObject:[NSNumber numberWithInt:0] forKey:@"Number"];
                    }
                }
            break;
        }
    }
    else //socket is dead
    {
        NSLog (@"NS Socket found to be invalid");
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] 			forKey:@"Status" account:self];
    }
    
    //now enumerate over each SB socket, and check for packets on each one.
    //if there is a packet, go to some kind of handling method
    
    //CODE GO HERE, MONKEY!
*/
}

- (void)update:(NSTimer *)timer
{
    ACCOUNT_STATUS status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
	
	switch (status)
	{
        case STATUS_ONLINE:
            [self getPackets:timer];
            break;
        case STATUS_OFFLINE:
        case STATUS_NA:
            break;
        case STATUS_CONNECTING:
            [self connect:timer];
            break;
        case STATUS_DISCONNECTING:
            [self disconnect];
            break;
	}
}

- (void)disconnect
{
    if([socket isValid] && [socket readyForSending])
    {
        [socket sendData:[@"OUT\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@">>> %@", @"OUT");
    }
    [socket release];
    
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];
}

/*- (void)connect
{    
    NSData *inData = nil;
    
    //We are connecting, yay.    
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];

    socket = [[AISocket socketWithHost:@"messenger.hotmail.com" port:1863] retain];
    
	//
    while(![socket readyForSending]) {}
    [socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
    
	//    
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    //[inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
    
	//
    while(![socket readyForSending]) {}
    [socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"INF 1");

	//
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    //[inData retain];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);    
    
	//
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
    
	//
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
	
    // code branches here, no longer repetitious
	
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
                
	//                                        
    while(![socket readyForSending]) {}
    [socket sendData:[[NSString stringWithFormat:@"USR 3 MD5 S %@\r\n", sendStr] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 3 MD5 S %@", sendStr]);
    
	//
    while(![socket readyForReceiving]) {}
    [socket getDataToNewline:&inData];
    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
            
    [self syncContactList];
    
    [self receiveInitialStatus];
    
    //We are connected, yay.
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:self];
    
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
                AIHandle *theHandle = [AIHandle 
                        handleWithServiceID:[[service handleServiceType] identifier]
                        UID:[message objectAtIndex:6]
                        serverGroup:@"MSN"
                        temporary:NO
                        forAccount:self];                                                
                [handleDict setObject:theHandle forKey:[message objectAtIndex:6]];
                
                [[owner contactController] handle:theHandle addedToAccount:self];
            }
            else if([[message objectAtIndex:2] isEqual:@"RL"])
            {
                //this is how we know we're done. when we get the last message of the reverse list.
                if([[message objectAtIndex:4] isEqual:[message objectAtIndex:5]])
                {
                    NSLog(@"done");
                    return;
                }
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
                        
        while(![socket readyForReceiving]) {}
    }
}

- (void)receiveInitialStatus
{
    NSData *inData = nil;
    
    while(![socket readyForSending]) {}
    [socket sendData:[@"CHG 5 NLN\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"CHG 5 NLN");
    
    //send a PNG so we know when we are done (when we get the QNG)
    while(![socket readyForSending]) {}
    [socket sendData:[@"PNG\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@">>> %@", @"PNG");
    
    while(![socket readyForReceiving]) {}
    while([socket readyForReceiving])
    {
        [socket getDataToNewline:&inData];
        NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
        
        if([[NSString stringWithCString:[inData bytes] length:[inData length]] isEqual:@"QNG\r\n"])
        {
            return;
        }
        
        NSArray *message = [[NSString stringWithCString:[inData bytes] length:[inData length]] componentsSeparatedByString:@" "];
        
        if([[message objectAtIndex:0] isEqual:@"ILN"]) //this is a person
        {
            AIHandle *theHandle = [handleDict objectForKey:[message objectAtIndex:3]];
            
            [[theHandle statusDictionary]
                setObject:[NSNumber numberWithInt:1]
                forKey:@"Online"];
            
            NSLog(@"%@",[[[message objectAtIndex:4] 
                    stringByTrimmingCharactersInSet:
                        [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]] urlDecode]);
            
            [[theHandle statusDictionary]
                setObject:[[[message objectAtIndex:4] 
                    stringByTrimmingCharactersInSet:
                        [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]] urlDecode]
                forKey:@"Display Name"];
                
            [[owner contactController] handleStatusChanged:theHandle
                modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", @"Display Name"]];

        }
        while(![socket readyForReceiving]) {}
    }
}*/

@end
