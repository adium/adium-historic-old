/*
 //
//  AIStressTestAccount.m
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIStressTestAccount.h"

@implementation AIStressTestAccount
//
- (void)initAccount
{
    handleDict = [[NSMutableDictionary alloc] init];
    chatDict = [[NSMutableDictionary alloc] init];

    commandHandle = [[AIHandle handleWithServiceID:@"TEMP"
                                               UID:@"Command"
                                       serverGroup:@"nope"
                                         temporary:YES
                                        forAccount:self] retain];
    [[adium contactController] handle:commandHandle addedToAccount:self];
    [handleDict setObject:commandHandle forKey:@"Command"];
    
    [[commandHandle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Online"];
    [[adium contactController] handleStatusChanged:commandHandle modifiedStatusKeys:[NSArray arrayWithObject:@"Online"] delayed:NO silent:NO];
    
    //
    commandChat = [[self chatForHandle:commandHandle] retain];

    //
    [self echo:@"Stress Test\r-------------\rYou must create handles before using any other commands\rUsage:\rcreate <count>\ronline <count> |silent|\roffline <count> |silent|\rmsgin <count> <spread> <message>\rmsginout <count> <spread> <message>\r"];
}

- (AIChat *)chatForHandle:(AIHandle *)inHandle
{
    AIChat *chat = [chatDict objectForKey:[inHandle UID]];

    if(!chat){
        AIListContact	*containingContact = [inHandle containingContact];

        chat = [AIChat chatForAccount:self];
        [chat addParticipatingListObject:containingContact];
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
        [[adium contentController] noteChat:chat forAccount:self];

        [chatDict setObject:chat forKey:[inHandle UID]];
    }

    return(chat);
}

//Return the default properties for this account
- (NSDictionary *)defaultProperties
{
    return([NSDictionary dictionary]);
}

// Return a view for the connection window
- (id <AIAccountViewController>)accountView{
    return(nil);
}

// Return a unique ID specific to THIS account plugin, and the user's account name
- (NSString *)accountID{
    return(@"TEST");
}

//The user's account name
- (NSString *)UID{
    return(@"TEST");
}

//The service ID (shared by any account code accessing this service)
- (NSString *)serviceID{
    return(@"TEST");
}

// Return a readable description of this account's username
- (NSString *)accountDescription
{
    return(@"Stress Test");
}


// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0 && ![(AIContentMessage *)object autoreply]){
        NSString	*message = [[(AIContentMessage *)object message] string];
        NSArray		*commands = [message componentsSeparatedByString:@" "];
        NSString	*type = [commands objectAtIndex:0];
        
        if([type compare:@"create"] == 0){
            int count = [[commands objectAtIndex:1] intValue];
            int i;
            
            for(i=0;i < count;i++){
                NSString	*UID = [NSString stringWithFormat:@"Buddy%i",i];
                AIHandle	*handle = [handleDict objectForKey:UID];

                if(!handle){
                    handle = [AIHandle handleWithServiceID:@"TEMP"
                                                       UID:UID
                                               serverGroup:[NSString stringWithFormat:@"Group%i",i/20]
                                                 temporary:NO
                                                forAccount:self];
                    [[adium contactController] handle:handle addedToAccount:self];
                    [handleDict setObject:handle forKey:UID];
                }
            }

            [self echo:[NSString stringWithFormat:@"Created %i handles",count]];
            
        }else if([type compare:@"online"] == 0){
            NSMutableArray	*handleArray = [NSMutableArray array];
            int 		count = [[commands objectAtIndex:1] intValue];
            BOOL 		silent = NO;
            int 		i;

            if([commands count] > 2) silent = ([(NSString *)@"silent" compare:[commands objectAtIndex:2]] == 0);
            for(i=0;i < count;i++){
                AIHandle	*handle;
                NSString	*UID = [NSString stringWithFormat:@"Buddy%i",i];

                if(handle = [handleDict objectForKey:UID]){
                    [handleArray addObject:handle];
                }
            }

            [NSTimer scheduledTimerWithTimeInterval:0.00001 target:self selector:@selector(timer_online:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:handleArray,@"handles",[NSNumber numberWithBool:silent],@"silent",nil] repeats:YES];
            [self echo:[NSString stringWithFormat:@"%i handles signing on %@",count,(silent?@"(Silently)":@"")]];

        }else if([type compare:@"offline"] == 0){
            int 	count = [[commands objectAtIndex:1] intValue];
            BOOL 	silent = NO;
            int 	i;

            if([commands count] > 2) silent = ([(NSString *)@"silent" compare:[commands objectAtIndex:2]] == 0);

            for(i=0;i < count;i++){
                AIHandle	*handle;
                NSString	*UID = [NSString stringWithFormat:@"Buddy%i",i];

                if(handle = [handleDict objectForKey:UID]){
                    [[handle statusDictionary] setObject:[NSNumber numberWithBool:NO] forKey:@"Online"];
                    [[adium contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Online"] delayed:silent silent:silent];
                }
            }

            [self echo:[NSString stringWithFormat:@"%i handles signed off %@",count,(silent?@"(Silently)":@"")]];

        }else if([type compare:@"msgin"] == 0){
            int 	count = [[commands objectAtIndex:1] intValue];
            int 	spread = [[commands objectAtIndex:2] intValue];
            NSString	*message = [commands objectAtIndex:3];

            [NSTimer scheduledTimerWithTimeInterval:0.00001 target:self selector:@selector(timer_msgin:) userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",[NSNumber numberWithInt:count],@"count",[NSNumber numberWithInt:spread],@"spread",message,@"message",nil] repeats:YES];

        }else if([type compare:@"msginout"] == 0){
            int 	count = [[commands objectAtIndex:1] intValue];
            int 	spread = [[commands objectAtIndex:2] intValue];
            NSString	*message = [commands objectAtIndex:3];

            [NSTimer scheduledTimerWithTimeInterval:0.00001 target:self selector:@selector(timer_msginout:) userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",[NSNumber numberWithInt:count],@"count",[NSNumber numberWithInt:spread],@"spread",message,@"message",[NSNumber numberWithBool:NO],@"in",nil] repeats:YES];
            
        }else{
            [self echo:[NSString stringWithFormat:@"Unknown command %@",type]];
        }
    }

    return(YES);
}


- (void)timer_online:(NSTimer *)inTimer
{
    NSMutableDictionary	*userInfo = [inTimer userInfo];
    NSMutableArray	*array = [userInfo objectForKey:@"handles"];
    AIHandle		*handle = [array lastObject];
    BOOL		silent = [[[inTimer userInfo] objectForKey:@"silent"] boolValue];
    
    [[handle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Online"];
    [[adium contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Online"] delayed:silent silent:silent];

    [array removeLastObject];
    if([array count] == 0) [inTimer invalidate];
}

- (void)timer_msgin:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
    NSString		*message = [userInfo objectForKey:@"message"];
    int			i = [[userInfo objectForKey:@"i"] intValue];
    int			count = [[userInfo objectForKey:@"count"] intValue];
    int			spread = [[userInfo objectForKey:@"spread"] intValue];

    AIHandle	*handle;
    NSString	*UID = [NSString stringWithFormat:@"Buddy%i",i%spread];

    if(handle = [handleDict objectForKey:UID]){
        AIContentMessage *messageObject;
        messageObject = [AIContentMessage messageInChat:[self chatForHandle:handle]
                                                withSource:[commandHandle containingContact]
                                            destination:self
                                                    date:nil
                                                message:[[[NSAttributedString alloc] initWithString:message attributes:[NSDictionary dictionary]] autorelease]
                                                autoreply:NO];
        [[adium contentController] addIncomingContentObject:messageObject];

    }

    i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if(i == count) [inTimer invalidate];
}


- (void)timer_msginout:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
    NSString		*message = [userInfo objectForKey:@"message"];
    int			i = [[userInfo objectForKey:@"i"] intValue];
    int			count = [[userInfo objectForKey:@"count"] intValue];
    int			spread = [[userInfo objectForKey:@"spread"] intValue];
    BOOL		msgIn = [[userInfo objectForKey:@"in"] boolValue];
    
    AIHandle	*handle;
    NSString	*UID = [NSString stringWithFormat:@"Buddy%i",i%spread];

    if(handle = [handleDict objectForKey:UID]){
        AIContentMessage *messageObject;
        if(msgIn){
            messageObject = [AIContentMessage messageInChat:[self chatForHandle:handle]
                                                 withSource:self
                                                destination:[commandHandle containingContact]
                                                       date:nil
                                                    message:[[[NSAttributedString alloc] initWithString:message attributes:[NSDictionary dictionary]] autorelease]
                                                  autoreply:YES];
            [[adium contentController] sendContentObject:messageObject];
        }else{
            messageObject = [AIContentMessage messageInChat:[self chatForHandle:handle]
                                                 withSource:[commandHandle containingContact]
                                                destination:self
                                                       date:nil
                                                    message:[[[NSAttributedString alloc] initWithString:message attributes:[NSDictionary dictionary]] autorelease]
                                                  autoreply:NO];
            [[adium contentController] addIncomingContentObject:messageObject];
        }

        [userInfo setObject:[NSNumber numberWithBool:!msgIn] forKey:@"in"];
    }

    i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if(i == count) [inTimer invalidate];
}




//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    return(YES);
}

//Initiate a new chat
- (AIChat *)openChatWithListObject:(AIListObject *)inListObject
{
    AIHandle	*handle = [handleDict objectForKey:[inListObject UID]];

    if(handle){
        return([self chatForHandle:handle]);
    }else{
        return(nil);
    }
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
    [chatDict removeObjectForKey:[[inChat listObject] UID]];
    return(YES); //Success
}



- (void)echo:(NSString *)string
{
    [self performSelector:@selector(_echo:) withObject:string afterDelay:0.00001];
}

- (void)_echo:(NSString *)string
{
    AIContentMessage *messageObject;
    messageObject = [AIContentMessage messageInChat:commandChat
                                         withSource:[commandHandle containingContact]
                                        destination:self
                                               date:nil
                                            message:[[[NSAttributedString alloc] initWithString:string attributes:[NSDictionary dictionary]] autorelease]
                                          autoreply:NO];
    [[adium contentController] addIncomingContentObject:messageObject];
}





// AIAccount_Status --------------------------------------------------------------------------------
// Returns an array of the status keys we support
- (NSArray *)supportedPropertyKeys
{
    return([NSArray array]);
}

// Respond to account status changes
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
}












@end
*/