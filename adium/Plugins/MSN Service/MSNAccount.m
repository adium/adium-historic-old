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
#import "MSNAccountViewController.h"
#include <openssl/md5.h>
#include <unistd.h>

#define TIMES_PER_SECOND 20.0
#define MAX_CONNECTION_PHASE	23

@interface MSNAccount (PRIVATE)
- (void)startConnect;
- (void)connect:(NSTimer *)timer;
- (void)update:(NSTimer *)timer;
- (void)disconnect;
- (BOOL)sendPayloadMessage:(NSString *)message onSocket:(AISocket *)Socket;
- (void)sendMessageHelper:(NSTimer *)timer;
- (void)startSBSessionHelper:(NSTimer *)timer;
- (unsigned long)getTrid:(BOOL)increment;
- (void)manageSBSocket:(NSMutableDictionary *)socketDict withHandle:(NSString *)handle;
@end

@implementation MSNAccount

/*********************/
/* AIAccount_Content */
/*********************/

- (BOOL)sendContentObject:(AIContentObject *)object
{
    NSLog(@"sendContentObject");
    if([[object type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        NSString	*message;
        AIHandle	*handle;
        AISocket	*sbSocket;
        
        //message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message] encodeFullString:YES];
        message = [[(AIContentMessage *)object message] string];
        handle = [[object destination] handleForAccount:self];
        sbSocket = [[switchBoardDict objectForKey:[handle UID]] objectForKey:@"Socket"];

        //create the payload
        NSString *payload = [NSString stringWithFormat:
            @"MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%@",
            message];
            
        if(sbSocket && [sbSocket isValid])//there's already an SB session
        {
            [self sendPayloadMessage:payload onSocket:sbSocket];
            
            return YES;
        }
        else // create a session
        {
            if(sbSocket && ![sbSocket isValid]) // if it's dead, don't dothis!
            {
                [switchBoardDict removeObjectForKey:[handle UID]];
            }
            NSLog(@"creating an SB session");
            [NSTimer scheduledTimerWithTimeInterval:1.0/TIMES_PER_SECOND
                target:self
                selector:@selector(startSBSessionHelper:)
                userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    @"Message", @"Type",
                    payload, @"Payload",
                    [handle UID], @"Handle",
                    [NSNumber numberWithInt:0], @"Phase", nil]
                repeats:YES];
            
            return YES;
        }
    }    
    if([[object type] isEqual:CONTENT_TYPING_TYPE] && [(AIContentTyping *)object typing])
    {
        AIHandle	*handle;
        AISocket	*sbSocket;

        handle = [[object destination] handleForAccount:self];
        sbSocket = [[switchBoardDict objectForKey:[handle UID]] objectForKey:@"Socket"];

        //create the payload
        NSString *payload = [NSString stringWithFormat:
            @"MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: %@\r\n\r\n\r\n",
            email];
            
        if(sbSocket && [sbSocket isValid])//there's already an SB session
        {
            [self sendPayloadMessage:payload onSocket:sbSocket];
            
            return YES;
        }
        else // create a session
        {
            if(sbSocket && ![sbSocket isValid]) // if it's dead, don't dothis!
            {
                [switchBoardDict removeObjectForKey:[handle UID]];
            }
            NSLog(@"creating an SB session");
            [NSTimer scheduledTimerWithTimeInterval:1.0/TIMES_PER_SECOND
                target:self
                selector:@selector(startSBSessionHelper:)
                userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    @"Message", @"Type",
                    payload, @"Payload",
                    [handle UID], @"Handle",
                    [NSNumber numberWithInt:0], @"Phase", nil]
                repeats:YES];
            
            return YES;
        }
    }
    return NO;
}

// Returns YES if the contact is available for receiving content of the specified type
- (BOOL)availableForSendingContentType:(NSString *)inType toChat:(AIChat *)inChat
{
    AIListObject 	*listObject = [inChat object];
    BOOL 		available = NO;

    if([inType compare:CONTENT_MESSAGE_TYPE] == 0 || [inType isEqual:CONTENT_TYPING_TYPE]){
        //If we are online
        if([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE){
            if(!inChat || !listObject){
                available = YES;

            }else{
                if([listObject isKindOfClass:[AIListContact class]]){
                    AIHandle	*handle = [(AIListContact *)listObject handleForAccount:self];

                    if(![[handleDict allValues] containsObject:handle] || [[[handle statusDictionary] objectForKey:@"Online"] intValue]){
                        available = YES;
                    }
                /*}else if([listObject isKindOfClass:[AIListChat class]]){
                    AIChat	*chat = [chatDict objectForKey:[listObject UID]];

                    if(!chat || [[listObject statusArrayForKey:@"Online"] greatestIntegerValue]){
                        available = YES;
                    }*/
                }
            }
        }
    }

    return(available);
}

- (BOOL)openChat:(AIChat *)inChat
{
    if([[inChat object] isKindOfClass:[AIListContact class]])
    {
        AIHandle *handle = [(AIListContact *)[inChat object] handleForAccount:self];
                
        [NSTimer scheduledTimerWithTimeInterval:1.0/TIMES_PER_SECOND
            target:self
            selector:@selector(startSBSessionHelper:)
            userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Empty", @"Type",
                [handle UID], @"Handle",
                [NSNumber numberWithInt:0], @"Phase",
                [NSNumber numberWithInt:0], @"Trid", nil]
            repeats:YES];
            
            return YES;
    }
    return(NO);
}

- (BOOL)closeChat:(AIChat *)inChat
{
    if([[inChat object] isKindOfClass:[AIListContact class]])
    {
        AIHandle *handle = [(AIListContact *)[inChat object] handleForAccount:self];
        
        //[switchBoardDict removeObjectForKey:[handle UID]];
        
        // This is NOT a permanent solution.  We need to add a way to queue up requests to the sbSocket.  Otherwise, it will
        // start forgetting to do things, which could get ugly.
        [[switchBoardDict objectForKey:[handle UID]] setObject:[NSNumber numberWithInt:1] forKey:@"Phase"];
        [[switchBoardDict objectForKey:[handle UID]] setObject:@"OUT\r\n" forKey:@"String"];
        
        return YES;
    }
    return NO;
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
    //email = [[self properties] objectForKey:@"Email"];
    //password = @"";
    //friendlyName = [[self properties] objectForKey:@"FriendlyName"];
    
    email = nil;
    password = nil;
    friendlyName = nil;
      
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
    
    handleDict = [[NSMutableDictionary alloc] init];
	switchBoardDict = [[NSMutableDictionary alloc] init];
    messageDict = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
    [handleDict release];
	[switchBoardDict release];
    [messageDict release];
    
    [super dealloc];
}

- (id <AIAccountViewController>)accountView
{
    return([MSNAccountViewController accountViewForOwner:owner account:self]);
}

- (NSString *)accountID //unique throught the whole app
{
    return [NSString stringWithFormat:@"MSN.%@",[propertiesDict objectForKey:@"Email"]];
}

- (NSString *)UID //unique to the service
{
    return [propertiesDict objectForKey:@"Email"];
}

- (NSString *)serviceID //service id
{
    return @"MSN";
}

- (NSString *)UIDAndServiceID //serviceid.uid
{
    return [NSString stringWithFormat:@"%@.%@",[self serviceID],[self UID]];
}

- (NSString *)accountDescription
{
    return [propertiesDict objectForKey:@"Email"];
}

- (NSArray *)supportedStatusKeys
{
    return([NSArray arrayWithObjects:@"Online", @"Offline", @"Hidden", @"Busy", @"Idle", @"Be Right Back", @"Away", @"On The Phone", @"Out to Lunch", @"Typing", nil]);
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
    [[owner accountController] passwordForAccount:self notifyingTarget:self selector:@selector(finishConnect:)];
}

- (void)finishConnect:(NSString *)inPassword
{
    if(inPassword && [inPassword length] != 0)
    {
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];
        
        if(email != [propertiesDict objectForKey:@"Email"])
        {
            [email release];
            email = [[propertiesDict objectForKey:@"Email"] copy];
        }
        if(friendlyName != [propertiesDict objectForKey:@"FriendlyName"])
        {
            [friendlyName release];
            friendlyName = [[propertiesDict objectForKey:@"FriendlyName"] copy];
        }
        if(password != inPassword)
        {
            [password release];
            password = [inPassword copy];
        }
        
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
                    //NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");

                    connectionPhase ++;
                }
                break;

            case 3:
                if ([socket getDataToNewline:&inData remove:YES]){
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                                                         length:[inData length]]);*/
                        
                    connectionPhase ++;
                }
                break;
                    
            case 4:
                if ([socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]]){
                    //NSLog(@">>> %@", @"INF 1");

                        connectionPhase ++;
                }
                break;
            
            case 5:
                if ([socket getDataToNewline:&inData remove:YES]){
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                                                         length:[inData length]]);*/
                                            
                    connectionPhase ++;
                }
                break;
                    
            case 6:
                if ([socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",
                    [email cString]] dataUsingEncoding:NSUTF8StringEncoding]]){
                    
                    /*NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",
                        [email cString]]);*/
                    connectionPhase ++;
                }
                break;
            
            case 7:
                if ([socket getDataToNewline:&inData remove:YES])
                {	
                    // In this phase, we receive data concerning the next server to connect to, 
                    // and then we connect.
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]);*/
                    
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
                    //NSLog(@">>> %@", @"VER 0 MSNP7 MSNP6 MSNP5 MSNP4 CVR0");
                    connectionPhase ++;
                }
                break;
            
            case 9:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]); */
                    connectionPhase ++;
                }
                break;
                    
            case 10:
                if ([socket sendData:[@"INF 1\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //NSLog(@">>> %@", @"INF 1");
                    connectionPhase ++;
                }
                break;
            
            case 11:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes]
                        length:[inData length]]); */
                    
                    connectionPhase ++;
                }
                break;
                    
            case 12:
                if ([socket sendData:[[NSString stringWithFormat:@"USR 2 MD5 I %s\r\n",
                    [email cString]] dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    /*NSLog(@">>> %@",[NSString stringWithFormat:@"USR 2 MD5 I %s",
                        [email cString]]);*/
                    connectionPhase ++;
                }
                break;
            
            case 13:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);*/
                    
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
                    
                    //NSLog (@"Password encrypted");
                    
                    [[timer userInfo] setObject:temp forKey:@"String"];
                    connectionPhase ++;
                }
                break;

            case 14:{
                NSString *temp = [[timer userInfo] objectForKey:@"String"];

                if ([socket sendData:[[NSString stringWithFormat:@"USR 3 MD5 S %@\r\n", temp]
                        dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //NSLog (@"Password being sent");
                    //NSLog(@">>> %@",[NSString stringWithFormat:@"USR 3 MD5 S %@", temp]);
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    connectionPhase ++;
                }
                break;

            }case 15:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    //NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                    //    length:[inData length]]); 
                    connectionPhase ++;
                }
                break;
                    
            // Contact List Update	//
            case 16:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);*/
                    NSArray *message = [[NSString stringWithCString:[inData bytes] 
                        length:[inData length]] 
                    componentsSeparatedByString:@" "];
                    
                    //this is some kind of message from the server
                    if([[message objectAtIndex:0] isEqual:@"MSG"]) 
                    {
                        //NSLog(@"%d",[[message objectAtIndex:3] intValue]);
                        [[timer userInfo] setObject:[message objectAtIndex:3] forKey:@"String"];
                        connectionPhase++;
                    }
                }
                break;
            
            case 17:
                if ([socket getData:&inData ofLength:
                    [[[timer userInfo] objectForKey:@"String"] intValue] remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);*/
                    [[timer userInfo] setObject:@"" forKey:@"String"];
                    connectionPhase++;
                }
                break;
            
            case 18:
                //now we send out our SYN
                if ([socket sendData:[@"SYN 4 0\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //NSLog(@">>> %@", @"SYN 4 0");
                    connectionPhase++;
                }
                break;
                    
            case 19:
                if ([socket getDataToNewline:&inData remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]); */
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
                                //NSLog(@"done");
                                connectionPhase++;
                            }
                        }
                    }
                    else if([[message objectAtIndex:0] isEqual:@"MSG"]) //this is some kind of message from the server
                    {
                        //NSLog(@"%d",[[message objectAtIndex:3] intValue]);
                        while(![socket getData:&inData ofLength:[[message objectAtIndex:3] intValue] remove:YES]) {}
                        /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                            length:[inData length]]);*/
                    }
                }
                break;
            case 20:
                if([socket sendData:
                        [[NSString stringWithFormat:@"REA 4 %@ %@\r\n",
                            email, [friendlyName urlEncode]]
                        dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //NSLog(@">>> %@", @"CHG 5 NLN");			
                    connectionPhase ++;
                }
                break;
                
            case 21:
                if([socket sendData:[@"CHG 5 NLN\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //NSLog(@">>> %@", @"CHG 5 NLN");			
                    connectionPhase ++;
                }
                break;
            
            case 22:
                if([socket sendData:[@"PNG\r\n" dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    //send a PNG so we know when we are done (when we get the QNG)
                    //NSLog(@">>> %@", @"PNG");
                    connectionPhase ++;
                }
                break;
            case 23:
                if([socket getDataToNewline:&inData remove:YES])
                {
                    /*NSLog(@"<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);*/
                    
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
                        
                        NSLog(@"Coming online: %@",[[[message objectAtIndex:4] 
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
                                                    modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", @"Display Name"]
                                                               delayed:NO
                                                                silent:NO];
            
                    }
                }
                else
                {
                    
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
        //NSLog (@"Socket found to be invalid");
        
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
                if([socket getDataToNewline:&inData remove:NO])
                {
                    //get the data, put it into message.
                    NSLog(@"<<<< %@",[NSString stringWithCString:[inData bytes] 
                        length:[inData length]]);
                    NSArray *message = [[NSString stringWithCString:[inData bytes] 
                        length:[inData length]-2] 
                    componentsSeparatedByString:@" "];
                    
                    //just convenience
                    NSString *command = [message objectAtIndex:0];
                    
                    //Should we be reading this? If yes, remove it from the socket's buffer.
                    if(![command isEqual:@"XFR"])
                    {
                        //remove the bytes
                        [socket removeDataBytes:[inData length]];                    
                        
                        //now since we know we should read it, process the packet
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
                        else if([command isEqualToString:@"ILN"])
                        {
                            AIHandle *theHandle = [handleDict objectForKey:[message objectAtIndex:3]];
                            
                            [[theHandle statusDictionary]
                                setObject:[NSNumber numberWithInt:1]
                                forKey:@"Online"];
                            
                            NSLog(@"Coming online: %@",[[[message objectAtIndex:4] 
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
                                                        modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", @"Display Name"]
                                                                   delayed:NO
                                                                    silent:NO];
                            
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
                            
                            //NSLog(@"%@ is online (NLN received)",[[message objectAtIndex:3] 
                            //                urlDecode]);
                            
                            [[theHandle statusDictionary]
                                setObject:[[message objectAtIndex:3]
                                            urlDecode]
                                forKey:@"Display Name"];

                            [[owner contactController] handleStatusChanged:theHandle
                                                        modifiedStatusKeys:[NSArray arrayWithObjects:@"Online", @"Display Name"]
                                                                   delayed:NO
                                                                    silent:NO];
                        }
                        else if([command isEqual:@"FLN"])
                        { // offline
                            AIHandle *theHandle = [handleDict objectForKey:
                                    [message objectAtIndex:1]];
                            
                            [[theHandle statusDictionary]
                                setObject:[NSNumber numberWithInt:0]
                                forKey:@"Online"];

                            [[owner contactController] handleStatusChanged:theHandle
                                                        modifiedStatusKeys:[NSArray arrayWithObject:@"Online"]
                                                                   delayed:NO
                                                                    silent:NO];
                        }
                        else if([command isEqual:@"RNG"])
                        {
                            //connect to the switchboard
                            NSArray *hostAndPort = [[message objectAtIndex:2]
                                componentsSeparatedByString:@":"];
                            AISocket *sbSocket = [AISocket 
                                socketWithHost:[hostAndPort objectAtIndex:0]
                                port:[[hostAndPort objectAtIndex:1] intValue]];
                            NSMutableDictionary *socketDict = nil;
                            
                            //[self sendPayloadMessage:[NSString stringWithFormat:@"ANS 1 %@ %@ %@\r\n", email, [message objectAtIndex:4], [message objectAtIndex:1]]onSocket:sbSocket];
                                
                            
                            if (socketDict = [switchBoardDict 
                                    objectForKey:[message objectAtIndex:5]])
                            {	
                                // Good, already have a socket
                            }
                            else //there's no socket already
                            {
                                [switchBoardDict setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:sbSocket, @"Socket", [NSNumber numberWithInt:0], @"Phase",  nil] 	forKey:[message objectAtIndex:5]];
                                
                                socketDict = [switchBoardDict 
                                    objectForKey:[message objectAtIndex:5]];
                            }
                            
                            [socketDict setObject:[NSNumber numberWithInt:1] forKey:@"Phase"];
                            [socketDict setObject:[NSString stringWithFormat:@"ANS 1 %@ %@ %@\r\n",
                                    email, [message objectAtIndex:4], [message objectAtIndex:1]] forKey:@"String"];
                            
                            [self manageSBSocket:socketDict withHandle:[message objectAtIndex:5]];
                        }
                        else if([command isEqual:@""])
                        {
                            //do stuff...
                        }
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

					if ([[[timer userInfo] objectForKey:@"Number"] intValue] == 3)
					{	// NOT command.  Might be a server-going-down notification or the like
                        NSLog (@"NOT command received with payload");
					}
					else
					{	// MSG command.  Payload has a standard format, including information on how to interpret it.
						NSDictionary *messageLoad = [MSNAccount parseMessage:inData];
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
            
            NSEnumerator	*numer = [switchBoardDict keyEnumerator];
            NSString		*handle = nil;
            //AISocket		*sbSocket = nil;
            NSMutableDictionary*	socketDict = nil;
            
            while (handle = [numer nextObject]) 
            {
                if (socketDict = [switchBoardDict objectForKey:handle])
                {
                    [self manageSBSocket:socketDict withHandle:handle];
                    /*if ([sbSocket isValid])
                    {
                        if([sbSocket getDataToNewline:&inData remove:YES])
                        {
                        }
                    }
                    else
                    {
                        NSLog (@"Socket for %@ went invalid", handle);
                        [switchBoardDict removeObjectForKey:handle];
                    }*/
                }
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
    //NSEnumerator	*enumerator;
    //AIHandle		*handle;
    
    // Set status as disconnecting
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_DISCONNECTING]
        forKey:@"Status" account:self];
    
    // Tell server we're going out
    if([socket isValid])
    {
        if([socket sendData:[@"OUT\r\n" dataUsingEncoding:NSUTF8StringEncoding]]){
            NSLog(@">>> %@", @"OUT");
        }
    }
    [socket release];
    socket = nil;
    
    //Flush all our handle status flags
    /*[[owner contactController] setHoldContactListUpdates:YES];
    enumerator = [[handleDict allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeAllStatusFlagsFromHandle:handle];
    }
    [[owner contactController] setHoldContactListUpdates:NO];*/

    //Remove all our handles
    [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
    [[owner contactController] handlesChangedForAccount:self];
    
    // Kill appropriate timers
    [stepTimer invalidate];	stepTimer = nil;
    
    // Set status as offline
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE]
        forKey:@"Status" account:self];
}

- (BOOL)sendPayloadMessage:(NSString *)message onSocket:(AISocket *)Socket
{
    if([message length] > 0)
    {
        NSString *packet;
        unsigned long	 thisTrid = [self getTrid:YES];
        
        packet = [NSString stringWithFormat:@"MSG %d A %d\r\n%@",
                thisTrid, [message length],
                message];
        
        NSLog (@"Sending packet:\n%@", packet);
    
        [messageDict setObject:packet forKey:[NSString stringWithFormat:@"%d", thisTrid]];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0/TIMES_PER_SECOND
            target:self
            selector:@selector(sendMessageHelper:)
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                [packet dataUsingEncoding:NSUTF8StringEncoding], @"Packet",
                Socket, @"Socket", nil]
            repeats:YES];
    
        return YES;
    }
    return NO;
}

- (void)sendMessageHelper:(NSTimer *)timer
{
    AISocket *Socket = [[timer userInfo] objectForKey:@"Socket"];
    NSData *data = [[timer userInfo] objectForKey:@"Packet"];
    
    if([Socket sendData:data])
    {
        [timer invalidate];
    }
}

- (void)startSBSessionHelper:(NSTimer *)timer
{ 
    NSData *inData = nil;
    NSString *temp = nil;
    unsigned long thisTrid = [[[timer userInfo] objectForKey:@"Trid"] intValue];
    
    switch([[[timer userInfo] objectForKey:@"Phase"] intValue])
    {
        case 0:
            if (thisTrid == 0)
            {
                thisTrid = [self getTrid:YES];
                [[timer userInfo] setObject:[NSNumber numberWithInt:thisTrid] forKey:@"Trid"];
            }
            
            temp = [NSString stringWithFormat:@"XFR %u SB\r\n", thisTrid];
            
            if ([socket sendData:[temp dataUsingEncoding:NSUTF8StringEncoding]])
                {
                    NSLog(@">>> %@", temp);
                    [[timer userInfo] setObject:[NSNumber numberWithInt:1] forKey:@"Phase"];
                }
            NSLog([[timer userInfo] objectForKey:@"Handle"]);
            break;
            
        case 1:
            if([socket getDataToNewline:&inData remove:NO])
            {
                NSLog(@"<<< %@", [NSString stringWithCString:[inData bytes] length:[inData length]]);
                
                NSArray *message = [[NSString stringWithCString:[inData bytes] 
                                        length:[inData length]] componentsSeparatedByString:@" "];
                
                NSLog(@"%u", [self getTrid:NO]);
                //is this command for us?
                if([[message objectAtIndex:0] isEqual:@"XFR"]
                    && [[message objectAtIndex:1] intValue] == thisTrid)
                {
                    //it's ours, take it out of the buffer
                    [socket removeDataBytes:[inData length]];
                    
                    //connect to the switchboard
                    NSArray *hostAndPort = [[message objectAtIndex:3]
                        componentsSeparatedByString:@":"];
                    AISocket *sbSocket = [AISocket socketWithHost:[hostAndPort objectAtIndex:0]
                                                port:[[hostAndPort objectAtIndex:1] intValue]];
                    
                    //add it to userInfo
                    [[timer userInfo] setObject:sbSocket forKey:@"Socket"];
                        
                    //now, setup the command for the next phase
                    [[timer userInfo] 
                        setObject:[NSString stringWithFormat:@"USR 1 %@ %@",
                            [self UID],
                            [message objectAtIndex:5]]
                        forKey:@"IDString"];
                    
                    //move on
                    [[timer userInfo] setObject:[NSNumber numberWithInt:2] forKey:@"Phase"];
                }
            }
            break;

        case 2:
            if([[[timer userInfo] objectForKey:@"Socket"]
                    sendData:[[[timer userInfo] objectForKey:@"IDString"]
                        dataUsingEncoding:NSUTF8StringEncoding]])
            {
                NSLog(@">>> %@", [[timer userInfo] objectForKey:@"IDString"]);
                
                //remove the temp variable
                [[timer userInfo] removeObjectForKey:@"IDString"];
                
                //move on
                [[timer userInfo] setObject:[NSNumber numberWithInt:3] forKey:@"Phase"];
            }
            break;
            
        case 3:
            if([[[timer userInfo] objectForKey:@"Socket"]
                    getDataToNewline:&inData remove:YES])
            {
                //uhoh! error!
                if(![[NSString stringWithCString:[inData bytes] length:[inData length]] 
                        hasPrefix:@"USR 1 OK"])
                {
                    //shout at the user
                    NSLog(@"Uhoh! Server killed the connection!");
                    
                    //stop this madness!
                    [timer invalidate];
                }
                else //Everything is OK!
                {
                    NSLog(@"<<< %@", 
                        [NSString stringWithCString:[inData bytes] length:[inData length]]);
                        
                    //prepare the message!
                    [[timer userInfo] setObject:[NSString stringWithFormat:@"CAL 2 %@\r\n",
                            [[timer userInfo] objectForKey:@"Handle"]]
                        forKey:@"Ring"];
                    
                    //move on
                    [[timer userInfo] setObject:[NSNumber numberWithInt:4] forKey:@"Phase"];
                }
            }
            break;
            
        case 4:
            //send the thing out
            if([[[timer userInfo] objectForKey:@"Socket"]
                    sendData:[[[timer userInfo] objectForKey:@"Ring"]
                        dataUsingEncoding:NSUTF8StringEncoding]])
            {
                NSLog(@">>> %@", [[timer userInfo] objectForKey:@"Ring"]);

                //remove the temp variable
                [[timer userInfo] removeObjectForKey:@"Ring"];
                
                //move on
                [[timer userInfo] setObject:[NSNumber numberWithInt:5] forKey:@"Phase"];
            }
            break;
            
        case 5:
            if([[[timer userInfo] objectForKey:@"Socket"]
                    getDataToNewline:&inData remove:YES])
            {
                //uhoh! error!
                if(![[NSString stringWithCString:[inData bytes] length:[inData length]] 
                        hasPrefix:@"CAL"])
                {
                    //shout at the user
                    NSLog(@"Uhoh! Error!"); // for now assume all errors are fatal
                    
                    //stop this madness!
                    [timer invalidate];
                }
                else //Everything is OK!
                {
                    NSLog(@"<<< %@", 
                        [NSString stringWithCString:[inData bytes] length:[inData length]]);

                    //finally add it to the dict
                    [switchBoardDict setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[[timer userInfo] objectForKey:@"Socket"], @"Socket", [NSNumber numberWithInt:0], @"Phase",  nil] 
                        forKey:[[timer userInfo] objectForKey:@"Handle"]];
                        
                    if(![[[timer userInfo] objectForKey:@"Type"] isEqual:@"Empty"])
                    {
                        [self sendPayloadMessage:[[timer userInfo] objectForKey:@"Message"]
                            onSocket:[[timer userInfo] objectForKey:@"Socket"]];
                    }
                    [timer invalidate];

                }
            }
            break;
        
    }
}

- (unsigned long)getTrid:(BOOL)increment
{
    static unsigned long lastTrid = 0; //0+1 = 1 :)
    
    if(increment)
    {
        if (lastTrid >= 4294967295UL)
            lastTrid = 1;
            
        lastTrid += 1;
    }
    return lastTrid;
}

- (void)manageSBSocket:(NSMutableDictionary *)socketDict withHandle:(NSString *)handle
{
    int	phase = [[socketDict objectForKey:@"Phase"] intValue];
    AISocket*	sbSocket = [socketDict objectForKey:@"Socket"];
    NSData*		theData = nil;
    
    if ([sbSocket isValid])
    {
        switch (phase)
        {
        case 0:	// Receive
            if ([sbSocket getDataToNewline:&theData remove:YES])
            {
                NSLog(@"sbSocket<<< %@", [NSString stringWithCString:[theData bytes] length:[theData length]-2]);
                NSArray *message = [[NSString stringWithCString:[theData bytes] length:[theData length]-2] 
                    componentsSeparatedByString:@" "];
                    
                NSString *command = [message objectAtIndex:0];
                
                if([command isEqualToString:@"MSG"]) //this needs to be outsourced to another function, because we have to read in the payload length. Stupid MSN.
                {
                    //we have to read in the playload, so this won't work.
                    
                    NSLog (@"Got message from %@!", handle);
                    
                    [socketDict setObject:[NSNumber numberWithInt:2] forKey:@"Phase"];	// Flag that we are receiving a payload
                    [socketDict setObject:[NSNumber numberWithInt:[[message lastObject] intValue]] forKey:@"LoadLength"];
                    [socketDict setObject:[NSString stringWithCString:[theData bytes] length:[theData length]-2] forKey:@"String"];
                    
                    /*NSDictionary* msgDict = [self parseMessage:theData];
                    
                    NSLog ([msgDict objectForKey:@"MSG Body"]);*/
            
                    //start on having messages show up
                    
                    /*
                    AIHandle *handle = [handleDict objectForKey:[message objectAtIndex:1]];
                    
                    // this next line is the only problem. there's no HTML to decode! Arrrrgh.
                    NSAttributedString *messageText = [AIHTMLDecoder decodeHTML:[msgDict objectForKey:@"MSG Body"]];
            
                    messageObject = [AIContentMessage messageInChat:[[owner contentController] chatWithListObject:[handle containingContact] onAccount:self]
                                                            withSource:[handle containingContact]
                                                        destination:self
                                                                date:nil
                                                            message:messageText];
                                                            
                    [[owner contentController] addIncomingContentObject:messageObject];*/
                }
                else if([command isEqualToString:@"JOI"])
                {
                    NSLog (@"JOI command received for user \"%@\" with address \"%@\"", [message objectAtIndex:2], [message objectAtIndex:1]);
                }
                else if([command isEqualToString:@"BYE"])
                {
                    NSLog (@"BYE command received for user w/ address \"%@\"", [message objectAtIndex:1]);
                    
                    [switchBoardDict removeObjectForKey:handle];
                }
                else if([command isEqualToString:@"ACK"])
                {
                    [messageDict removeObjectForKey:[message objectAtIndex:1]];
                }
                else if([command isEqualToString:@"NAK"])
                {
                    //Shout at the user
                    NSLog(@"Faiure to send message %@", 
                        [messageDict objectForKey:[message objectAtIndex:1]]);
                        
                    [[owner interfaceController] handleErrorMessage:@"MSN Error"
                        withDescription:[NSString stringWithFormat:@"Failure to send message:\n%@",
                            [messageDict objectForKey:[message objectAtIndex:1]]]];
                    
                    [messageDict removeObjectForKey:[message objectAtIndex:1]];
                }
                else
                {
                    NSLog (@"Socket received unrecognized command:");
                    NSLog ([NSString stringWithCString:[theData bytes] length:[theData length]-2]);
                }
            }
            break;
            
        case 1:	// Send
            if([sbSocket sendData:[[socketDict objectForKey:@"String"]
                    dataUsingEncoding:NSUTF8StringEncoding]])
            {
                NSLog(@"sbSocket>>> %@", [socketDict objectForKey:@"String"]);
                
                //reset the string
                [socketDict setObject:@"" forKey:@"String"];
                
                //go back to reading
                [socketDict setObject:[NSNumber numberWithInt:0] forKey:@"Phase"];
                
            }
            break;
            
        case 2:	// Receive payload
        {
            unsigned short loadLength = [[socketDict objectForKey:@"LoadLength"] intValue];
            
            if([sbSocket getData:&theData ofLength:loadLength remove:YES])
            {	// AISocket will cache the data and return FALSE until it has retrieved the entire payload
                NSLog (@"Received payload of length %d. Payload:\n%@", loadLength, [NSString stringWithCString:[theData bytes] length:[theData length]]);
                NSArray *message = [[socketDict objectForKey:@"String"] componentsSeparatedByString:@" "];
                NSString *command = [message objectAtIndex:0];
                
                if ([command isEqualToString:@"MSG"])
                {
                    NSDictionary *messageLoad = [MSNAccount parseMessage:theData];
                    NSString	*contentType = [[[messageLoad objectForKey:@"Content-Type"] componentsSeparatedByString:@";"] objectAtIndex:0];
                    
                    NSLog (@"***MSN Message received of type %@, content: %@", contentType, [messageLoad objectForKey:@"MSG Body"]);
                
                    if ([contentType isEqualToString:@"text/plain"])
                    {	// Received a message
                        AIContentMessage	*messageObject = nil;
                        AIListObject		*contact = [[handleDict objectForKey:handle] containingContact];
                        // (Do cool formatting stuff here)
                        NSLog (@"MSN Got message, sending to interface"); 
                        
                        // Not typing anymore, they sent!
                        AIHandle *Handle = [handleDict objectForKey:handle];
                        [[Handle statusDictionary] 
                            setObject:[NSNumber numberWithInt:NO] forKey:@"Typing"];
                        [[owner contactController] handleStatusChanged:Handle
                                                    modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]
                                                               delayed:NO
                                                                silent:NO];
                        
                        //Add a content object for the message
                        messageObject = [AIContentMessage messageInChat:[[owner contentController] chatWithListObject:contact onAccount:self]
                                         withSource:contact
                                        destination:self
                                               date:nil
                                            message:[[[NSAttributedString alloc] initWithString:[messageLoad objectForKey:@"MSG Body"]] autorelease]];
                        [[owner contentController] addIncomingContentObject:messageObject];
                    }
                    else if([messageLoad objectForKey:@"TypingUser"] != nil)
                    {
                        NSLog(@"typing");
                        //w00t. typing. ph33r.
                        AIHandle *Handle = [handleDict objectForKey:handle];
                        
                        [[Handle statusDictionary] 
                            setObject:[NSNumber numberWithInt:YES] forKey:@"Typing"];
                        [[owner contactController] handleStatusChanged:Handle
                                                    modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]
                                                               delayed:NO
                                                                silent:NO];
                    }
                }
                else
                {
                    NSLog (@"MSN received received payload after command \"%@\", will not interpret.", [socketDict objectForKey:@"String"]);
                }
            
                //go back to reading
                [socketDict setObject:[NSNumber numberWithInt:0] forKey:@"Phase"];
            }
            
            break;
        }
        }
    }
    else
    {
        NSLog (@"Socket for %@ went invalid", handle);
        [switchBoardDict removeObjectForKey:handle];
    }
}

/*************************/
/* SPECIAL SHINY METHODS */
/*************************/

// Returns fields as NSString key/value pairs, and the body under the key "MSG Body"
+ (NSDictionary *)parseMessage:(NSData *)payload
{
	int curMode = 0;
	
	NSMutableDictionary		*dict = [[NSMutableDictionary alloc] init];
	NSString				*loadStr = [NSString stringWithCString:[payload bytes] length:[payload length]],
							*curField = nil, *curValue = nil;
	unsigned long			lastCharIndex = 0, curCharIndex = 0;
	unichar					curChar;
	BOOL					done = NO;
	NSRange					range;
	
    NSLog (@"Parsing message payload of length %d.", [payload length]);
    
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
					//NSLog (@"MSN message values: %@: %@", curField, curValue);
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
		
		if (curCharIndex + 1 >= [loadStr length]) done = TRUE;	// +1 because we often look one past it for checks.
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
			//NSLog (@"MSN message values: %@: %@", curField, curValue);
			[dict setObject:curValue forKey:curField];
		}
	}
	else
	{
		NSLog (@"Did not recognize encoding: %@.  Will assume UTF-8", encoding);
                
		range.location = curCharIndex;
		range.length = ([payload length] - curCharIndex);
		
		if (range.length > 0)
			curValue = [NSString stringWithCString:[[payload subdataWithRange:range] bytes] length:range.length];
		else
			curValue = @"";
		
		// Store values in dictionary
		if (curField != nil)
		{
			//NSLog (@"MSN message values: %@: %@", curField, curValue);
			[dict setObject:curValue forKey:curField];
		}
	}
	
	// Make the immutable dictionary
	NSDictionary* returnDict = [NSDictionary dictionaryWithDictionary:dict];
	[dict release];
	
	return (returnDict);
}
@end