
//
//  AIStressTestAccount.m
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//

#ifdef DEVELOPMENT_BUILD

#import "AIStressTestAccount.h"
#import "AIStressTestPlugin.h"

@implementation AIStressTestAccount
//
- (void)initAccount
{
    chatDict = [[NSMutableDictionary alloc] init];
	listObjectArray = [[NSMutableArray alloc] init];
	
	commandContact = [[[adium contactController] contactWithService:STRESS_TEST_SERVICE_IDENTIFIER 
														  accountID:[self uniqueObjectID]
																UID:@"Command"] retain];
    [commandContact setRemoteGroupName:@"Command"];
    [commandContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:YES];
    
    //
    [self echo:@"Stress Test\r-------------\rYou must create contacts before using any other commands\rUsage:\rcreate <count>\ronline <count> |silent|\roffline <count> |silent|\rmsgin <count> <spread> <message>\rmsginout <count> <spread> <message>\rgroupchat <count> <message>\rcrash"];
}

//Return the default properties for this account
- (NSDictionary *)defaultProperties
{
    return([NSDictionary dictionary]);
}

// Return a unique ID specific to THIS account plugin, and the user's account name
- (NSString *)accountID{
    return([self uniqueObjectID]);
}

//The user's account name
- (NSString *)UID{
    return(@"TEST");
}

//The service ID (shared by any account code accessing this service)
- (NSString *)serviceID{
    return(STRESS_TEST_SERVICE_IDENTIFIER);
}

- (NSString *)displayName
{
    return(@"Stress Test");
}

// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0 && ![(AIContentMessage *)object isAutoreply]){
        NSString	*message = [[(AIContentMessage *)object message] string];
        NSArray		*commands = [message componentsSeparatedByString:@" "];
        NSString	*type = [commands objectAtIndex:0];
        
        if([type compare:@"create"] == 0){
            int count = [[commands objectAtIndex:1] intValue];
            int i;
            
            for(i=0;i < count;i++){
                NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i];
				AIListContact	*contact;
				
				contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
															  accountID:[self uniqueObjectID]
																	UID:buddyUID];
				[contact setRemoteGroupName:[NSString stringWithFormat:@"Group %i", (int)(i/5.0)]];
            }
			
            [self echo:[NSString stringWithFormat:@"Created %i handles",count]];
            
        }else if([type compare:@"online"] == 0){
            NSMutableArray	*handleArray = [NSMutableArray array];
            int 		count = [[commands objectAtIndex:1] intValue];
            BOOL 		silent = NO;
            int 		i;
			
            if([commands count] > 2) silent = ([[commands objectAtIndex:2] isEqualToString:@"silent"]);
			
            for(i=0;i < count;i++){
				AIListContact	*contact;
                NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i];
				
				contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
															  accountID:[self uniqueObjectID]
																	UID:buddyUID];
				[handleArray addObject:contact];
            }
			
			if (silent) [[adium contactController] delayListObjectNotifications];

            [NSTimer scheduledTimerWithTimeInterval:0.00001
											 target:self
										   selector:@selector(timer_online:)
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:handleArray,@"handles",
																							[NSNumber numberWithBool:silent],@"silent",nil] 
											repeats:YES];
            [self echo:[NSString stringWithFormat:@"%i handles signing on %@",count,(silent?@"(Silently)":@"")]];
			
        }else if([type compare:@"offline"] == 0){
            int 	count = [[commands objectAtIndex:1] intValue];
            BOOL 	silent = NO;
			BOOL	shouldNotify = !silent;
            int 	i;
			
			NSString	*identifier = [[service handleServiceType] identifier];
			NSString	*myUniqueObjectID = [self uniqueObjectID];
			NSString	*ONLINE = @"Online";
			
            if([commands count] > 2) silent = ([(NSString *)@"silent" compare:[commands objectAtIndex:2]] == 0);
			
			if (silent) [[adium contactController] delayListObjectNotifications];

            for(i=0;i < count;i++){
				AIListContact	*contact;
				
				contact = [[adium contactController] existingContactWithService:identifier
																	  accountID:myUniqueObjectID
																			UID:[NSString stringWithFormat:@"Buddy%i",i]];
				[contact setStatusObject:nil forKey:ONLINE notify:shouldNotify];
            }

			if (silent) [[adium contactController] endListObjectNotificationsDelay];
			
            [self echo:[NSString stringWithFormat:@"%i handles signed off %@",count,(silent?@"(Silently)":@"")]];
			
        }else if([type compare:@"msgin"] == 0){
            int 		count = [[commands objectAtIndex:1] intValue];
			int 		spread = [[commands objectAtIndex:2] intValue];
            NSString	*messageIn = [commands objectAtIndex:3];
			
            [NSTimer scheduledTimerWithTimeInterval:0.00001
											 target:self
										   selector:@selector(timer_msgin:)
										   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",
											   [NSNumber numberWithInt:count],@"count",
											   [NSNumber numberWithInt:spread],@"spread",
											   messageIn,@"message",nil] 
											repeats:YES];
			
        }else if([type compare:@"msginout"] == 0){
            int 		count = [[commands objectAtIndex:1] intValue];
            int 		spread = [[commands objectAtIndex:2] intValue];
            NSString	*messageOut = [commands objectAtIndex:3];
			
            [NSTimer scheduledTimerWithTimeInterval:0.00001 
											 target:self 
										   selector:@selector(timer_msginout:)
										   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",
											   [NSNumber numberWithInt:count],@"count",
											   [NSNumber numberWithInt:spread],@"spread",
											   messageOut,@"message",
											   [NSNumber numberWithBool:NO],@"in",nil] 
											repeats:YES];
            
		}else if ([type compare:@"groupchat"] == 0) {
            int 		count = [[commands objectAtIndex:1] intValue];
			NSString	*messageIn = [commands objectAtIndex:2];
			
			[NSTimer scheduledTimerWithTimeInterval:0.00001
											 target:self
										   selector:@selector(timer_groupchat:)
										   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"i",
											   [NSNumber numberWithInt:count],@"count",
											   messageIn,@"message",nil] 
											repeats:YES];	
			
        }else if ([type compare:@"crash"] == 0){
            NSMutableArray *help = [[NSMutableArray alloc] init];
            [help addObject:nil];   
        }else{
            [self echo:[NSString stringWithFormat:@"Unknown command %@",type]];
        }
    }
	
    return(YES);
}

- (void)timer_online:(NSTimer *)inTimer
{
    NSMutableDictionary	*userInfo = [inTimer userInfo];
    NSMutableArray		*array = [userInfo objectForKey:@"handles"];
    AIListContact		*contact = [array lastObject];
	BOOL				silent = [[userInfo objectForKey:@"silent"] boolValue];
    
	[contact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];

	//Apply any changes
	[contact notifyOfChangedStatusSilently:silent];

    [array removeLastObject];
    if([array count] == 0){
		if (silent) [[adium contactController] endListObjectNotificationsDelay];

		[inTimer invalidate];
	}
}

- (void)timer_msgin:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
    NSString		*message = [userInfo objectForKey:@"message"];
    int				i = [[userInfo objectForKey:@"i"] intValue];
    int				count = [[userInfo objectForKey:@"count"] intValue];
    int				spread = [[userInfo objectForKey:@"spread"] intValue];
	
    AIListContact	*contact;
    NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i%spread];
	
    if((contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
													  accountID:[self uniqueObjectID]
															UID:buddyUID])){
        AIContentMessage *messageObject;
        messageObject = [AIContentMessage messageInChat:[[adium contentController] chatWithContact:contact 
																					 initialStatus:nil]
											 withSource:contact
                                            destination:self
												   date:nil
                                                message:[[[NSAttributedString alloc] initWithString:message
																						 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
											  autoreply:NO];
        [[adium contentController] receiveContentObject:messageObject];
		
    }
	
    i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if(i == count) [inTimer invalidate];
}


- (void)timer_msginout:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
    NSString		*message = [userInfo objectForKey:@"message"];
    int				i = [[userInfo objectForKey:@"i"] intValue];
    int				count = [[userInfo objectForKey:@"count"] intValue];
    int				spread = [[userInfo objectForKey:@"spread"] intValue];
    BOOL			msgIn = [[userInfo objectForKey:@"in"] boolValue];
    
    AIListContact	*contact;
    NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",i%spread];
	
    if((contact = [[adium contactController] contactWithService:[[service handleServiceType] identifier]
													  accountID:[self uniqueObjectID]
															UID:buddyUID])){
        AIContentMessage *messageObject;
        if(msgIn){
            messageObject = [AIContentMessage messageInChat:[[adium contentController] chatWithContact:contact
																						 initialStatus:nil]
                                                 withSource:self
                                                destination:contact
                                                       date:nil
                                                    message:[[[NSAttributedString alloc] initWithString:message
																							 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
                                                  autoreply:YES];
            [[adium contentController] sendContentObject:messageObject];
        }else{
            messageObject = [AIContentMessage messageInChat:[[adium contentController] chatWithContact:contact
																						 initialStatus:nil]
                                                 withSource:contact
                                                destination:self
                                                       date:nil
                                                    message:[[[NSAttributedString alloc] initWithString:message 
																							 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
                                                  autoreply:NO];
            [[adium contentController] receiveContentObject:messageObject];
        }
		
        [userInfo setObject:[NSNumber numberWithBool:!msgIn] forKey:@"in"];
    }
	
    i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if(i == count) [inTimer invalidate];
}

- (void)timer_groupchat:(NSTimer *)inTimer
{
    NSMutableDictionary *userInfo = [inTimer userInfo];
	NSString		*message = [userInfo objectForKey:@"message"];
    int				i = [[userInfo objectForKey:@"i"] intValue];
    int				count = [[userInfo objectForKey:@"count"] intValue];
	int				j;
    AIListContact	*contact;
	AIContentMessage *messageObject;
	
	if( i == 0 ) {
		
		//listObjectArray = [NSMutableArray arrayWithCapacity:4];

		for(j = 0; j < count; j++) {
			NSString		*buddyUID = [NSString stringWithFormat:@"Buddy%i",j];
			[listObjectArray addObject:[[adium contactController] contactWithService:[[service handleServiceType] identifier]
																		   accountID:[self uniqueObjectID]
																				 UID:buddyUID]];
		}
		
		
		commandChat = [[adium contentController] chatWithContact:[listObjectArray objectAtIndex:0] initialStatus:nil];
		
		messageObject = [AIContentMessage messageInChat:[[adium contentController] chatWithContact:[listObjectArray objectAtIndex:0] 
																					 initialStatus:nil]
											 withSource:[listObjectArray objectAtIndex:0]
											destination:self
												   date:nil
												message:[[[NSAttributedString alloc] initWithString:message
																						 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
											  autoreply:NO];
		[[adium contentController] receiveContentObject:messageObject];
		
	} else if( i < count ) {
		[commandChat addParticipatingListObject:[listObjectArray objectAtIndex:i]];
		messageObject = [AIContentMessage messageInChat:commandChat
											 withSource:[listObjectArray objectAtIndex:i]
											destination:self
												   date:nil
												message:[[[NSAttributedString alloc] initWithString:message
																						 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
											  autoreply:NO];
		[[adium contentController] receiveContentObject:messageObject];
		
		
	}	
	
	i++;
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"i"];
    if(i == count) [inTimer invalidate];
}



//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
	if ([inType isEqualToString:CONTENT_MESSAGE_TYPE]){
		return(YES);
	}else{
		return(NO);
	}
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
	[[chat statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
	
	[chatDict setObject:chat forKey:[[chat listObject] UID]];
	
    return(YES);
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
    messageObject = [AIContentMessage messageInChat:[[adium contentController] chatWithContact:commandContact
																				 initialStatus:nil]
                                         withSource:commandContact
                                        destination:self
                                               date:nil
                                            message:[[[NSAttributedString alloc] initWithString:string
																					 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
                                          autoreply:NO];
    [[adium contentController] receiveContentObject:messageObject];
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

#endif