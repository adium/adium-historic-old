//
//  ESMessageEvents.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 27 2004.
//

#import "ESMessageEvents.h"

@implementation ESMessageEvents

- (void)installPlugin
{
	//Register the events we generate
	[[adium contactAlertsController] registerEventID:CONTENT_MESSAGE_SENT withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTENT_MESSAGE_RECEIVED withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTENT_MESSAGE_RECEIVED_FIRST withHandler:self];
	
	//Install our observers
    [[adium notificationCenter] addObserver:self selector:@selector(handleMessageEvent:) name:Content_DidSendContent object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(handleMessageEvent:) name:Content_DidReceiveContent object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(handleMessageEvent:) name:Content_FirstContentRecieved object:nil];
}

- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = NSLocalizedString(@"Is sent a message",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = NSLocalizedString(@"Sends a message",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = NSLocalizedString(@"Sends an initial message",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = NSLocalizedString(@"Message Sent",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = NSLocalizedString(@"Message Received",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = NSLocalizedString(@"Message Received (New)",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = @"Message Sent";
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = @"Message Received";
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = @"Message Received (New)";
	}else{
		description = @"";
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = NSLocalizedString(@"When %@ is sent a message by you",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = NSLocalizedString(@"When %@ sends a message to you",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = NSLocalizedString(@"When %@ sends an initial message to you",nil);
	}else{
		description = NSLocalizedString(@"Unknown",nil);
	}
	
	return([NSString stringWithFormat:description, [listObject displayName]]);
}

- (void)handleMessageEvent:(NSNotification *)notification
{
	AIChat			*chat = [notification object];
	AIListObject	*listObject = [chat listObject];
	
	if ([[notification name] isEqualToString:Content_DidSendContent]){
		[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_SENT
										 forListObject:listObject
											  userInfo:chat];

	}else if ([[notification name] isEqualToString:Content_DidReceiveContent]){
		[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED
										 forListObject:listObject
											  userInfo:chat];
		
	}else if ([[notification name] isEqualToString:Content_FirstContentRecieved]){
		[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED_FIRST
										 forListObject:listObject
											  userInfo:chat];

	}
}

@end
