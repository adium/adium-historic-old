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
- (NSDictionary *)parseMessage:(NSData *)payload;
- (BOOL)sendMessage:(NSString *)message onSocket:(AISocket *)socket;
@end

@implementation MSNAccount

/*********************/
/* AIAccount_Content */
/*********************/

- (BOOL)sendContentObject:(AIContentObject *)object
{
    if([[object type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        NSString	*message;
        AIHandle	*handle;
        AISocket	*sbSocket;
        
        message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message] encodeFullString:YES];
        handle = [[object destination] handleForAccount:self];
        sbSocket = [switchBoardDict objectForKey:handle];
        
        if(sbSocket)//there's already an SB session
        {
            //create the payload, then the whole packet
            NSString *payload = [NSString stringWithFormat:
                @"MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n%@",
                message];
            NSString *packet = [NSString stringWithFormat:@"MSG 4 N %d\r\n%@",
                [payload length], payload];
                
            return([self sendMessage:packet onSocket:sbSocket]);
        }
        else // create a session
        {
            return NO;
        }
    }
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
	switchBoardDict = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
    [handleDict release];
	[switchBoardDict release];
    
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
	
	if (socket)
	{
		[socket release];
		socket = nil;
	}
    
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
                if ([socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]]){
                    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");

                    connectionPhase ++;
                }
                break;

            case 3:
                if ([socket getDataToNewline:&inData remove:YES]){
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                                                         length:[inData length]]);
                        
                    connectionPhase ++;
                }
                break;
                    
            case 4:
                if ([socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]]){
                    NSLog(@">>> %@", @"INF 1");

                        connectionPhase ++;
                }
                break;
            
            case 5:
                if ([socket getDataToNewline:&inData remove:YES]){
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                                                         length:[inData length]]);
                                            
                    connectionPhase ++;
                }
                break;
                    
            case 6:
                if ([socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",
                    [screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]]){
                    
                    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",
                        [screenName cString]]);
                    connectionPhase ++;
                }
                break;
            
            case 7:
                if ([socket getDataToNewline:&inData remove:YES])
                {	
                    // In this phase, we receive data concerning the next server to connect to, 
                    // and then we connect.
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
                if ([socket sendData:[@"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0\r\n"
                        dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
                    connectionPhase ++;
                }
                break;
            
            case 9:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]);
                    connectionPhase ++;
                }
                break;
                    
            case 10:
                if ([socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@", @"INF 1");
                    connectionPhase ++;
                }
                break;
            
            case 11:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]); 
                    
                    connectionPhase ++;
                }
                break;
                    
            case 12:
                if ([socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",
                    [screenName cString]] dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",
                        [screenName cString]]);
                    connectionPhase ++;
                }
                break;
            
            case 13:
                if ([socket getDataToNewline:&inData remove:YES])
                {
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

            case 14:{
                NSString *temp = [[timer userInfo] objectForKey:@"String"];

                if ([socket sendData:[[NSString stringWithFormat:@"USR 3 MD5 S %@\r\n", temp]
                        dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog (@"Password being sent");
                    NSLog(@">>> %@",[NSString stringWithFormat:@"USR 3 MD5 S %@", temp]);
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    connectionPhase ++;
                }
                break;

            }case 15:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] length:[inData length]]); 
                    
                    connectionPhase ++;
                }
                break;
                    
            // Contact List Update	//
            case 16:
                if ([socket getDataToNewline:&inData remove:YES])
                {
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
                if ([socket getData:&inData ofLength:
                    [[[timer userInfo] objectForKey:@"String"] intValue] remove:YES])
                {
                    NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    connectionPhase++;
                }
                break;
            
            case 18:
                //now we send out our SYN
                if ([socket sendData:[@"SYN 4 0\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@", @"SYN 4 0");
                    connectionPhase++;
                }
                break;
                    
            case 19:
                if ([socket getDataToNewline:&inData remove:YES])
                {
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
                        while(![socket getData:&inData ofLength:[[message objectAtIndex:3] intValue] remove:YES]) {}
                        NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                            length:[inData length]]);
                    }
                }
                break;
                
            case 20:
                if([socket sendData:[@"CHG 5 NLN\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@", @"CHG 5 NLN");			
                    connectionPhase ++;
                }
                break;
            
            case 21:
                if([socket sendData:[@"PNG\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //send a PNG so we know when we are done (when we get the QNG)
                    NSLog(@">>> %@", @"PNG");
                    connectionPhase ++;
                }
                break;
            case 22:
                if([socket getDataToNewline:&inData remove:YES])
                {
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
		
		[socket release];
		socket = nil;
    }
}

- (void)getPackets:(NSTimer *)timer
{
	NSData *inData = nil; //don't want old data hanging around
    if ([socket isValid])
    {
		//NSLog (@"MSN getPackets, mode: %@", [[timer userInfo] objectForKey:@"Number"]);
        switch([[[timer userInfo] objectForKey:@"Number"] intValue])
        {
            case 0: //read
                if([socket getDataToNewline:&inData remove:YES])
                {
                    //get the data, put it into message.
                    NSLog(@"<<<< %@",[NSString stringWithCString:[inData bytes] 
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
                        
                        //format the stuff in the right format.
                        temp = [NSString stringWithFormat:@"QRY %d msmsgs@msnmsgr.com 32\r\n%@", 231, temp];
                        
                        //set it in userInfo
                        [[timer userInfo] setObject:temp forKey:@"String"];
                        
                        //go to sending stage
                        [[timer userInfo] setObject:[NSNumber numberWithInt:1] forKey:@"Number"];
                    }
                    else if([command isEqual:@"MSG"])
                    {
						//Set payload length
						[[timer userInfo] setObject:[message objectAtIndex:([message count] - 1)] forKey:@"String"];
						
						//go to Message payload stage
						[[timer userInfo] setObject:[NSNumber numberWithInt:2] forKey:@"Number"];
					}
                    else if([command isEqual:@"NOT"])
                    {
						//Set payload length
						[[timer userInfo] setObject:[message objectAtIndex:([message count] - 1)] forKey:@"String"];
						
						//go to Message payload stage
						[[timer userInfo] setObject:[NSNumber numberWithInt:3] forKey:@"Number"];
					}
                    else if([command isEqual:@"NLN"])
                    {

                        AIHandle *theHandle = [handleDict objectForKey:
                            [message objectAtIndex:2]];
                        
                        [[theHandle statusDictionary]
                            setObject:[NSNumber numberWithInt:1]
                            forKey:@"Online"];
                        
                        NSLog(@"%@",[[message objectAtIndex:3] 
                                        urlDecode]);
                        
                        [[theHandle statusDictionary]
                            setObject:[[message objectAtIndex:3]
                                        urlDecode]
                            forKey:@"Display Name"];
                            
                        [[owner contactController] handleStatusChanged:theHandle
                            modifiedStatusKeys:
                                [NSArray arrayWithObjects:@"Online", @"Display Name"]];
                    }
                    else if([command isEqual:@"FLN"])
                    { // offline
                        AIHandle *theHandle = [handleDict objectForKey:
                                [message objectAtIndex:1]];
                        
                        [[theHandle statusDictionary]
                            setObject:[NSNumber numberWithInt:0]
                            forKey:@"Online"];
                            
                        [[owner contactController] handleStatusChanged:theHandle
                            modifiedStatusKeys:
                                [NSArray arrayWithObject:@"Online"]];
                    }
                    else if([command isEqual:@""])
                    {
                        //do stuff...
                    }
                    
                }
                break;
                
            case 1: //Send
                if([socket sendData:[[[timer userInfo] objectForKey:@"String"]
                        dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@", [[timer userInfo] objectForKey:@"String"]);
                    
                    //reset the string
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    
                    //go back to reading
                    [[timer userInfo] setObject:[NSNumber numberWithInt:0] forKey:@"Number"];
                    
                }
                break;
                
            case 2: //MSG //Receive a payload command, the length is in String.
            case 3: //NOT //(Afterward, the data will be in String, AS AN NSDATA. BE CAREFUL) <-- May be changed
			{		
				//get the length
				int length = [[[timer userInfo] objectForKey:@"String"] intValue];
				
				//if we don't have temp, create it
				//if([[timer userInfo] objectForKey:@"temp"] == nil)
				//{
				//	[[timer userInfo] setObject:[[NSMutableData alloc] init] forKey:@"temp"];
				//}
				
                if([socket getData:&inData ofLength:length remove:YES])
                {	// AISocket will cache the data and return FALSE until it has retrieved the entire payload

					//put the data in String.
					//[[[timer userInfo] objectForKey:@"temp"] appendData:inData];
					
					//put the final data into String.
					//[[timer userInfo] setObject:[[timer userInfo] objectForKey:@"temp"]
					//	forKey:@"String"];
					
					//remove temp
					//[[timer userInfo] removeObjectForKey:@"temp"];
					
					if ([[[timer userInfo] objectForKey:@"Number"] intValue] == 3)
					{	// NOT command.  Might be a server-going-down notification or the like
					}
					else
					{	// MSG command.  Payload has a standard format, including information on how to interpret it.
						NSDictionary *messageLoad = [self parseMessage:inData];
						NSString	*contentType = [[[messageLoad objectForKey:@"Content-Type"] componentsSeparatedByString:@";"] objectAtIndex:0];
						
						NSLog (@"MSN Message received of type %@", contentType);
						
						if ([contentType isEqualToString:@"text/plain"])
						{
							NSLog (@"MSN Plain text message.");
						}
						else if ([contentType isEqualToString:@"text/x-msmsgscontrol"])
						{
							NSLog (@"MSN A user is typing.");
						}
						else if ([contentType isEqualToString:@"text/x-msmsgsprofile"])
						{
							NSLog (@"MSN Received user profile.");
						}
						else if ([contentType isEqualToString:@"text/x-msmsgsinitialemailnotification"])
						{
							NSLog (@"MSN new mail!");
						}
						else if ([contentType isEqualToString:@"application/x-msmsgsemailnotification"])
						{
							NSLog (@"MSN new mail! MSN2");
						}
						else if ([contentType isEqualToString:@"text/x-msmsgsemailnotification"])
						{
							NSLog (@"MSN new mail! MSN3-7");
						}
						else if ([contentType isEqualToString:@"text/x-msmsgsactivemailnotification"])
						{
							NSLog (@"MSN Hotmail activity");
						}
						else if ([contentType isEqualToString:@"application/x-msmsgssystemmessage"])
						{
							NSLog (@"MSN System Message!!! \r%@", [messageLoad objectForKey:@"MSG Body"]);
						}
					}
					
					//go back to reading packets, we are done here.
					[[timer userInfo] setObject:[NSNumber numberWithInt:0] forKey:@"Number"];
                }
            break;
			}
        }
    }
    else //socket is dead
    {
        NSLog (@"NS Socket found to be invalid");
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] 			forKey:@"Status" account:self];
		
		[socket release];
		socket = nil;
    }
}

- (void)update:(NSTimer *)timer
{
    ACCOUNT_STATUS status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
	
	switch (status)
	{
        case STATUS_ONLINE:
            [self getPackets:timer];
            //now enumerate over each SB socket, and check for packets on each one.
            //if there is a packet, go to some kind of handling method
            
            NSEnumerator	*numer = [switchBoardDict objectEnumerator];
            AISocket		*sbSocket = nil;
            
            //while (sbSocket = [numer nextObject])
            {
                //CODE GO HERE, MONKEY!
            }
            
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
    if([socket isValid])
    {
        if([socket sendData:[@"OUT\r\n" dataUsingEncoding:NSUTF8StringEncoding]]){
            NSLog(@">>> %@", @"OUT");
        }
    }
    [socket release];
    
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];
}

// Returns fields as key/value pairs, and the body under the key "MSG Body"
- (NSDictionary *)parseMessage:(NSData *)payload
{
	int curMode = 0;
	
	NSMutableDictionary		*dict = [[NSMutableDictionary alloc] init];
	NSString				*loadStr = [NSString stringWithCString:[payload bytes] length:[payload length]],
							*curField = nil, *curValue = nil;
	unsigned long			lastCharIndex = 0, curCharIndex = 0;
	unichar					curChar;
	BOOL					done = NO;
	NSRange					range;
	
	while (!done)
	{
		curChar = [loadStr characterAtIndex:curCharIndex];
	
		switch (curMode)
		{
		case 0:	// Scanning in a field
			if (curChar == ':')
			{				
				range.location = lastCharIndex;
				range.length = curCharIndex - lastCharIndex;
				
				if ([loadStr characterAtIndex:(curCharIndex + 1)] == ' ')
				{	// The space after the colon is not required by the format, but not part of the
					// field value either
					curCharIndex++;
				}
				
				if (range.length != 0)
				{
					curField = [loadStr substringWithRange:range];
				}
				else
				{
					NSLog (@"Message with empty field name.");
					curField = nil;
				}
				curMode = 1;
				lastCharIndex = curCharIndex + 1;
			}
			else if (curChar == '\r')
			{
				if (lastCharIndex == curCharIndex)
				{	// EXIT LOOP
					done = TRUE;	// The tell-tale blank line was found!
					curCharIndex++;
				}
				else
				{	// Strange error: field name that ends in newline: "badfield\n\r" instead of colon: "goodfield: value\n\r"
					// Report error:
					range.location = lastCharIndex;
					range.length = curCharIndex - lastCharIndex;
					
					if (range.length != 0)
					{
						NSLog (@"Badly formed field: (no colon) %@", [loadStr substringWithRange:range]);
					}
					else
					{
						NSLog (@"Badly formed field (no colon)");
					}
					
					// Proceed: (reset counting variables, at next line's start)
					if ([loadStr characterAtIndex:(curCharIndex + 1)] == '\r')
						curCharIndex++;
					lastCharIndex = curCharIndex + 1;
				}
			}
			break;
			
			
		case 1: // Scanning in a value
			if (curChar == '\n')
			{
				// Put the range of the text into string
				range.location = lastCharIndex;
				range.length = curCharIndex - lastCharIndex;
				
				if (range.length != 0)
					curValue = [loadStr substringWithRange:range];
				else
					curValue = @"";
				
				// Store values in dictionary
				if (curField != nil)
				{
					NSLog (@"MSN message values: %@: %@", curField, curValue);
					[dict setObject:curValue forKey:curField];
				}
				
				// Move on
				//curCharIndex++;	// To account for following required '\r'
				curMode = 0;
				lastCharIndex = curCharIndex + 1;
			}
		
			break;
		}
		
		++curCharIndex;
		
		if (curCharIndex >= [loadStr length]) done = TRUE;
	}
	
	// Get the message body
	
	NSString*	encoding = [dict objectForKey:@"Content-Type"];
	curField = @"MSG Body";
	//range.length = 13;
	//range.location = range.length - ([encoding length] - 1);
	
	
	if ([encoding rangeOfString:@"charset=UTF-8"].location != NSNotFound)//[encoding compare:@"charset=UTF-8" options:nil range:range])//contains:@"charset=UTF-8"])
	{
		range.location = curCharIndex;
		range.length = ([payload length] - curCharIndex);
		
		if (range.length > 0)
			curValue = [NSString stringWithCString:[[payload subdataWithRange:range] bytes] length:range.length];
		else
			curValue = @"";
		
		// Store values in dictionary
		if (curField != nil)
		{
			NSLog (@"MSN message values: %@: %@", curField, curValue);
			[dict setObject:curValue forKey:curField];
		}
	}
	else
	{
		NSLog (@"Did not recognize encoding: %@ (%@)", encoding, [encoding substringWithRange:range]);
	}
	
	// Make the immutable dictionary
	NSDictionary* returnDict = [NSDictionary dictionaryWithDictionary:dict];
	[dict release];
	
	return (returnDict);
}

- (BOOL)sendMessage:(NSString *)message onSocket:(AISocket *)socket
{
    return YES;
}

@end
