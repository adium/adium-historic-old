//
//  DCMessageContextDisplayPlugin.m
//  Adium
//
//  Created by David Clark on Tuesday, March 23, 2004.
//

#import "DCMessageContextDisplayPlugin.h"

@interface DCMessageContextDisplayPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation DCMessageContextDisplayPlugin
- (void)installPlugin
{
	/*
	NSLog(@"----DCMessageContextDisplayPlugin installed");
	
	//Observe new message windows
	[[adium notificationCenter] addObserver:self selector:@selector(addContextDisplayToWindow:) name:Chat_DidOpen object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(addContentDisplayToWindow:) name:Content_FirstContentRecieved object:nil];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
	 */
}

- (void)uninstallPlugin
{
    
}

- (void)dealloc
{
    [super dealloc];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTEXT_DISPLAY] == 0){

    }
}


//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (void)addContextDisplayToWindow:(NSNotification *)notification
{
    AIChat				*chat;
    AIContentMessage    *responseContent;
    NSAttributedString  *message;

	
	chat = (AIChat *)[notification object];
	message = [[[NSAttributedString alloc] initWithString:@"MY TEMPORARY MESSAGE"] retain];
	
	responseContent = [AIContentMessage messageInChat:chat
										   withSource:[chat account]
										  destination:[chat listObject]
												 date:nil
											  message:message
											autoreply:NO];
	
	[[adium contentController] displayContentObject:responseContent];

	NSLog(@"----Added Response: %@ to chat: %@",message,chat);
	[message release];

}

@end
