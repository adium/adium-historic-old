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
- (void)syncContactList;
- (void)receiveInitialStatus;
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
        userInfo:nil/*[[NSMutableDictionary alloc] initWithObjectsAndKeys:]*/
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
				[socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
				connectionPhase ++;
			}
			break;
		
		case 3:
			if ([socket readyForReceiving])
			{
				[socket getDataToNewline:&inData];
				//[inData retain];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
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
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]); 
				
				connectionPhase ++;
			}
			break;
			
		case 6:
			if ([socket readyForSending])
			{
				[socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
				connectionPhase ++;
			}
			break;
		
		case 7:
			if ([socket readyForReceiving])
			{	// In this phase, we receive data concerning the next server to connect to, and then
				// we connect.
				[socket getDataToNewline:&inData];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
				
				NSArray *hostAndPort = [[[[NSString stringWithCString:[inData bytes] length:[inData length]] 
					componentsSeparatedByString:@" "]
						objectAtIndex:3] componentsSeparatedByString:@":"];
						
				[socket release];
				socket = [[AISocket 
						socketWithHost:[hostAndPort objectAtIndex:0]
						port:[[hostAndPort objectAtIndex:1] intValue]]
					retain];
				connectionPhase += 2;	// The only reason I'm skipping a phase number is b/c
										// I had an extra phase number in earlier.  Didn't want
										// to renumber.
			}
			break;
			
		case 9:
			if ([socket readyForSending])
			{
				[socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
				connectionPhase ++;
			}
			break;
		
		case 10:
			if ([socket readyForReceiving])
			{
				[socket getDataToNewline:&inData];
				//[inData retain];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
				connectionPhase ++;
			}
			break;
			
		case 11:
			if ([socket readyForSending])
			{
				[socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@", @"INF 1");
				connectionPhase ++;
			}
			break;
		
		case 12:
			if ([socket readyForReceiving])
			{
				[socket getDataToNewline:&inData];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]); 
				
				connectionPhase ++;
			}
			break;
			
		case 13:
			if ([socket readyForSending])
			{
				[socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",[screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",[screenName cString]]);
				connectionPhase ++;
			}
			break;
		
		case 14:
			if ([socket readyForReceiving])
			{
				[socket getDataToNewline:&inData];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
				
				// Use the info passed by the server to produce a properly encrypted password
				NSData *tempData = [[NSString stringWithFormat:@"%@%@",
						[[[NSString stringWithCString:[inData bytes] length:[inData length]-2] 					componentsSeparatedByString:@" "] objectAtIndex:4], 
						password]
						dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
				
				NSData *mdData = [NSData dataWithBytes:(const int *)MD5([tempData bytes],
						[tempData length], NULL) length:16];
					
				temp = [mdData description];
				temp = [temp substringWithRange:NSMakeRange(1,[temp length]-2)];
				temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				temp = [[[temp componentsSeparatedByString:@" "] componentsJoinedByString:@""] retain];
				
				NSLog (@"Password encrypted");
				
				connectionPhase ++;
			}
			break;
			
		case 15:
			if ([socket readyForSending])
			{
				NSLog (@"Password being sent");
				[socket sendData:[[NSString stringWithFormat:@"USR 3 MD5 S %@\r\n", temp] dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@",[NSString stringWithFormat:@"USR 3 MD5 S %@", temp]);
				[temp release];
				temp = nil;
				connectionPhase ++;
			}
			break;
		
		case 16:
			if ([socket readyForReceiving])
			{
				[socket getDataToNewline:&inData];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]); 
				
				connectionPhase ++;
			}
			break;
			
		// Contact List Update	//
		case 17:
			if ([socket readyForReceiving])
			{
				[socket getDataToNewline:&inData];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
				NSArray *message = [[NSString stringWithCString:[inData bytes] length:[inData length]] componentsSeparatedByString:@" "];
				
				
				if([[message objectAtIndex:0] isEqual:@"MSG"]) //this is some kind of message from the server
				{
					NSLog(@"%d",[[message objectAtIndex:3] intValue]);
					temp = [[message objectAtIndex:3] retain];
					connectionPhase++;
				}
			}
			break;
		
		case 18:
			if ([socket readyForReceiving])
			{
				[socket getData:&inData ofLength:[temp intValue]];
				NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
				[temp release];
				temp = nil;
				connectionPhase++;
			}
			break;
		
		case 19:
			//now we send out our SYN, only the first time, though.
			if ([socket readyForSending])
			{
				[socket sendData:[@"SYN 4 0\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
				NSLog(@">>> %@", @"SYN 4 0");
				connectionPhase++;
			}
			break;
			
		case 20:
		
			if ([socket readyForReceiving])
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
							connectionPhase++;
						}
					}
				}
				else if([[message objectAtIndex:0] isEqual:@"MSG"]) //this is some kind of message from the server
				{
					NSLog(@"%d",[[message objectAtIndex:3] intValue]);
					while(![socket readyForReceiving]) {}
					[socket getData:&inData ofLength:[[message objectAtIndex:3] intValue]];
					NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]);
				}
			}
			break;
			
		case 21:
			NSLog (@"MSN Last phase!");
			connectionPhase ++;
			break;
			
		default:
			[[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self];
			break;
		}
	}
	else
	{
		NSLog (@"Socket found to be invalid");
		
		[[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
	}
}

- (void)update:(NSTimer *)timer
{
    ACCOUNT_STATUS status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
	
	switch (status)
	{
	case STATUS_ONLINE:
		break;
	case STATUS_OFFLINE:
	case STATUS_NA:
		break;
	case STATUS_CONNECTING:
		[self connect:timer];
		break;
	case STATUS_DISCONNECTING:
		break;
	}
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
    
}*/

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
}

@end
