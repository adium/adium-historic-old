//
//  AITypingNotificationPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//

#import "AITypingNotificationPlugin.h"
#import <Adium/Adium.h>

@interface AITypingNotificationPlugin (PRIVATE)
- (void)_sendTypingState:(AITypingState)typingState toChat:(AIChat *)chat;
- (void)_processTypingInView:(NSText<AITextEntryView> *)inTextEntryView;
@end

#define CAN_RECEIVE_TYPING		@"CanReceiveTyping"
#define WE_ARE_TYPING			@"WeAreTyping"

#define ENTERED_TEXT_TIMER		@"EnteredTextTimer"
#define ENTERED_TEXT_INTERVAL   3.0
@implementation AITypingNotificationPlugin

- (void)installPlugin
{
    //Register as an entry filter
    [[adium contentController] registerTextEntryFilter:self];

    //typingDict = [[NSMutableDictionary alloc] init];
    //messagedDict = [[NSMutableDictionary alloc] init];

    [[adium notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_FirstContentRecieved object:nil];
}

//Watch incoming content.  Once we are messaged by a contact, that contact may receive typing notifications
- (void)didReceiveContent:(NSNotification *)notification
{
    AIChat		*chat = [notification object];
    NSNumber		*cleared;

    cleared = [chat statusObjectForKey:CAN_RECEIVE_TYPING];

    //Clear this contact for receiving typing notifications
    if(!cleared){
        [chat setStatusObject:[NSNumber numberWithBool:1]
					   forKey:CAN_RECEIVE_TYPING
					   notify:NotifyNever];
    }
}

- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _processTypingInView:inTextEntryView];
}

- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _processTypingInView:inTextEntryView];
}

- (void)_processTypingInView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIChat				*chat = [inTextEntryView chat];
	
    if(chat && [chat statusObjectForKey:CAN_RECEIVE_TYPING] != nil){
		NSNumber		*previousTypingNumber = [chat statusObjectForKey:WE_ARE_TYPING];
		AITypingState   previousTypingState = (previousTypingNumber ? [previousTypingNumber intValue] : AINotTyping);
		AITypingState   currentTypingState;
		NSTimer			*enteredTextTimer;

		//Invalidate any timer currently watching this chat for switching it to entered text
		if (enteredTextTimer = [chat statusObjectForKey:ENTERED_TEXT_TIMER]){
			[enteredTextTimer invalidate];
		}
		
	     
		//Determine if this change indicated the user was typing or indicated the user had no longer entered text
		if ([[inTextEntryView attributedString] length] != 0){
			//The text just changed, and the length is non-zero; the user is therefore typing
			currentTypingState = AITyping;
			
			//Schedule the switchover to "Entered Text" after ENTERED_TEXT_INTERVAL
			enteredTextTimer = [NSTimer scheduledTimerWithTimeInterval:ENTERED_TEXT_INTERVAL
																target:self
															  selector:@selector(_switchToEnteredText:)
															  userInfo:chat
															   repeats:NO];
			//Keep track of the timer object for early invalidation if necessary
			[chat setStatusObject:enteredTextTimer 
						   forKey:ENTERED_TEXT_TIMER
						   notify:NotifyNever];
			
		}else{
			//The text just changed, and the length is zero; the user is therefore not typing and has not entered text
			currentTypingState = AINotTyping;
		}
		
		//We don't want to send the same typing value more than once
        if(previousTypingState != currentTypingState) {
			[self _sendTypingState:currentTypingState toChat:chat];
		}
    }    
}

- (void)_sendTypingState:(AITypingState)typingState toChat:(AIChat *)chat
{
    AIAccount		*account = [chat account];
    AIContentTyping	*contentObject;

    //Send typing content object (It will go directly to the account since typing content isn't tracked or filtered)
    contentObject = [AIContentTyping typingContentInChat:chat
                                              withSource:account
                                             destination:nil
											 typingState:typingState];
    [[adium contentController] sendContentObject:contentObject];
    
    //Remember the state
	[chat setStatusObject:(typingState != AINotTyping ? [NSNumber numberWithInt:typingState] : nil)
				   forKey:WE_ARE_TYPING
				   notify:NotifyNever];
}

- (void)_switchToEnteredText:(NSTimer *)inTimer
{
	AIChat  *chat = [inTimer userInfo];
	[self _sendTypingState:AIEnteredText toChat:chat];
}

- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIChat	*chat = [inTextEntryView chat];

    //Send a 'not-typing' message to this contact
    if(([chat integerStatusObjectForKey:WE_ARE_TYPING] != AINotTyping) && ([chat statusObjectForKey:CAN_RECEIVE_TYPING] != nil)){
        [self _sendTypingState:AINotTyping toChat:chat];
    }

    //We could choose to de-clear the contact for typing notifications here as well
    //AIChat		*chat = [inTextEntryView chat];
    //[[chat statusDictionary] removeObjectForKey:CAN_RECEIVE_TYPING];
}

@end
