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
- (void)_addTypingTimerForChat:(AIChat *)chat;
- (void)_resetTypingTimerForChat:(AIChat *)chat;
- (void)_removeTypingTimerForChat:(AIChat *)chat;
@end

#define CAN_RECEIVE_TYPING		@"CanReceiveTyping"
#define WE_ARE_TYPING			@"WeAreTyping"

#define ENTERED_TEXT_TIMER		@"EnteredTextTimer"
#define ENTERED_TEXT_INTERVAL   3.0

@implementation AITypingNotificationPlugin

- (void)installPlugin
{
    //Register as an entry filter and observe content
	[[adium contentController] registerTextEntryFilter:self];
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


//Text entry -----------------------------------------------------------------------------------------------------------
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIChat		*chat = [inTextEntryView chat];
	
    //Send a 'not-typing' message to this contact
    if(([chat integerStatusObjectForKey:WE_ARE_TYPING] != AINotTyping) && ([chat statusObjectForKey:CAN_RECEIVE_TYPING] != nil)){
        [self _sendTypingState:AINotTyping toChat:chat];
    }
	
	//Remove our typing timer
	[self _removeTypingTimerForChat:chat];
	
    //We could choose to de-clear the contact for typing notifications here as well
    //AIChat		*chat = [inTextEntryView chat];
    //[[chat statusDictionary] removeObjectForKey:CAN_RECEIVE_TYPING];
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
    AIChat		*chat = [inTextEntryView chat];
	
    if(chat && [chat statusObjectForKey:CAN_RECEIVE_TYPING] != nil){
		NSTimer			*enteredTextTimer = [chat statusObjectForKey:ENTERED_TEXT_TIMER];
		NSNumber		*previousTypingNumber = [chat statusObjectForKey:WE_ARE_TYPING];
		AITypingState   previousTypingState = (previousTypingNumber ? [previousTypingNumber intValue] : AINotTyping);
		AITypingState   currentTypingState;

		//Determine if this change indicated the user was typing or indicated the user had no longer entered text
		if([[inTextEntryView attributedString] length] != 0){ //User is typing
			currentTypingState = AITyping;

			if(enteredTextTimer){
				[self _resetTypingTimerForChat:chat];
			}else{
				[self _addTypingTimerForChat:chat];
			}

		}else{ //User is not typing
			currentTypingState = AINotTyping;
			[self _removeTypingTimerForChat:chat];
		}
		
		//We don't want to send the same typing value more than once
        if(previousTypingState != currentTypingState){
			[self _sendTypingState:currentTypingState toChat:chat];
		}
    }    
}


//Typing state ---------------------------------------------------------------------------------------------------------
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
	[self _removeTypingTimerForChat:chat];
}


//Typing timer ---------------------------------------------------------------------------------------------------------
//Add, remove, or reset the timer responsible for detecting when the user stops typing
- (void)_addTypingTimerForChat:(AIChat *)chat
{
	NSTimer	*enteredTextTimer = [NSTimer scheduledTimerWithTimeInterval:ENTERED_TEXT_INTERVAL
																 target:self
															   selector:@selector(_switchToEnteredText:)
															   userInfo:chat
																repeats:NO];
	[chat setStatusObject:enteredTextTimer forKey:ENTERED_TEXT_TIMER notify:NotifyNever];
}

- (void)_resetTypingTimerForChat:(AIChat *)chat
{
	NSTimer	*enteredTextTimer = [chat statusObjectForKey:ENTERED_TEXT_TIMER];
	if(enteredTextTimer){
		[enteredTextTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:ENTERED_TEXT_INTERVAL]];
	}
}

- (void)_removeTypingTimerForChat:(AIChat *)chat
{
	NSTimer	*enteredTextTimer = [chat statusObjectForKey:ENTERED_TEXT_TIMER];
	if(enteredTextTimer){
		[enteredTextTimer invalidate];
		[chat setStatusObject:nil forKey:ENTERED_TEXT_TIMER notify:NotifyNever];
	}
}

@end
