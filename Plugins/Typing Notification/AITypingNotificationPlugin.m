//
//  AITypingNotificationPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AITypingNotificationPlugin.h"
#import "AITypingNotificationPreferences.h"
#import <Adium/Adium.h>

@interface AITypingNotificationPlugin (PRIVATE)
- (void)_sendTypingState:(AITypingState)typingState toChat:(AIChat *)chat;
- (void)_processTypingInView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)_addTypingTimerForChat:(AIChat *)chat;
- (void)_resetTypingTimerForChat:(AIChat *)chat;
- (void)_removeTypingTimerForChat:(AIChat *)chat;
@end

#define WE_ARE_TYPING			@"WeAreTyping"

#define ENTERED_TEXT_TIMER		@"EnteredTextTimer"
#define ENTERED_TEXT_INTERVAL   3.0

#define SUPPRESS_TYPING_NOTIFICATIONS	@"SuppressTypingNotificationChanges"

@implementation AITypingNotificationPlugin

- (void)installPlugin
{
    //Preferences
    preferences = [[AITypingNotificationPreferences preferencePane] retain];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_TYPING_NOTIFICATIONS];
	
    //Register as an entry filter and observe content
	[[adium contentController] registerTextEntryFilter:self];

	//Observe message sending
	[[adium notificationCenter] addObserver:self
								   selector:@selector(didSendMessage:)
									   name:Interface_DidSendEnteredMessage
									 object:nil];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	disableTypingNotifications = [[prefDict objectForKey:KEY_DISABLE_TYPING_NOTIFICATIONS] boolValue];
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
    if([chat integerStatusObjectForKey:WE_ARE_TYPING] != AINotTyping){
        [self _sendTypingState:AINotTyping toChat:chat];
    }
	
	//Remove our typing timer
	[self _removeTypingTimerForChat:chat];
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
	
    if(chat){
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

/* 
 * @brief Suppress typing notifications when sending a message
 *
 * Some protocols require a 'Stopped typing' notification to be sent along with an instant message.  Other protocols
 * implicitly assume that typing has stopped with an incoming message and the extraneous typing notification may cause
 * strange behavior.  To prevent this, we allow accounts to suppress these typing notifications. 
 */
- (void)didSendMessage:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	
	if([[chat account] suppressTypingNotificationChangesAfterSend]){
		//Set the suppress typing flag for this chat
		[chat setStatusObject:[NSNumber numberWithBool:YES]
					   forKey:SUPPRESS_TYPING_NOTIFICATIONS
					   notify:NotifyNever];
		
		//Clear the flag after a short delay
		[self performSelector:@selector(_removeSuppressFlagFromChat:) withObject:chat afterDelay:0.0000001];
	}
}
- (void)_removeSuppressFlagFromChat:(AIChat *)chat
{
	[chat setStatusObject:nil
				   forKey:SUPPRESS_TYPING_NOTIFICATIONS
				   notify:NotifyNever];
}



//Typing state ---------------------------------------------------------------------------------------------------------
- (void)_sendTypingState:(AITypingState)typingState toChat:(AIChat *)chat
{
	if(![chat integerStatusObjectForKey:SUPPRESS_TYPING_NOTIFICATIONS] &&
	   (([chat integerStatusObjectForKey:WE_ARE_TYPING] != AINotTyping && typingState == AINotTyping) //We need this to allow 'stop typing' changes incase the user turns off the preference while they're typing
		|| !disableTypingNotifications)){
		AIAccount		*account = [chat account];
		AIContentTyping	*contentObject;
		
		//Send typing content object (It will go directly to the account since typing content isn't tracked or filtered)
		contentObject = [AIContentTyping typingContentInChat:chat
												  withSource:account
												 destination:nil
												 typingState:typingState];
		[[adium contentController] sendContentObject:contentObject];
    }

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
