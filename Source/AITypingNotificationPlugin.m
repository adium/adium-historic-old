/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AITypingNotificationPlugin.h"
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>

@interface AITypingNotificationPlugin (PRIVATE)
- (void)_sendTypingState:(AITypingState)typingState toChat:(AIChat *)chat;
- (void)_processTypingInView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)_addTypingTimerForChat:(AIChat *)chat;
- (void)_resetTypingTimer:(NSTimer *)enteredTextTimer forChat:(AIChat *)chat;
- (void)_removeTypingTimer:(NSTimer *)enteredTextTimer forChat:(AIChat *)chat;
@end

#define WE_ARE_TYPING			@"WeAreTyping"

#define ENTERED_TEXT_TIMER		@"EnteredTextTimer"
#define ENTERED_TEXT_INTERVAL   3.0

/*
 * @class AITypingNotificationPlugin
 * @brief Component to send typing notifications in open chats
 *
 * The possible typing notifications are 'actively typing', 'entered text', and 'not typing'.
 * Not all protocols will support the 'entered text' notification; it may be treated as actively typing as appropriate.
 */
@implementation AITypingNotificationPlugin

/*
 * @brief Install
 */
- (void)installPlugin
{
    //Register as an entry filter and observe content
	[[adium contentController] registerTextEntryFilter:self];

	//Observe message sending
	[[adium notificationCenter] addObserver:self
								   selector:@selector(didSendMessage:)
									   name:Interface_DidSendEnteredMessage
									 object:nil];
}

//Text entry -----------------------------------------------------------------------------------------------------------
/*
 * @brief Text entry view was opened
 *
 * Sent because we are a text entry view filter; ignored.
 */
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView {};

/*
 * @brief Text entry view will close
 *
 * Be sure to clear the typing state of a chat when its text entry view closes
 */
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIChat		*chat = [inTextEntryView chat];
	
    //Send a 'not-typing' message to this chat
    if([chat integerStatusObjectForKey:WE_ARE_TYPING] != AINotTyping){
        [self _sendTypingState:AINotTyping toChat:chat];
    }
	
	//Remove our typing timer
	[self _removeTypingTimer:[chat statusObjectForKey:ENTERED_TEXT_TIMER] forChat:chat];
}

/*
 * @brief A string was added to a text entry view
 */
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _processTypingInView:inTextEntryView];
}

/*
 * @brief The contents of a text entry view changed
 */
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _processTypingInView:inTextEntryView];
}

/*
 * @brief Process the current typing state in a text entry view
 *
 * When the user makes a change or adds text, mark the chat with an AITyping state.
 * After a timeout with no changes, change that state to AIEnteredText.
 *
 * When the user makes a change resulting in an empty text view, however, clear the typing state.
 */
- (void)_processTypingInView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIChat		*chat = [inTextEntryView chat];
	
    if(chat){
		NSTimer			*enteredTextTimer;
		NSNumber		*previousTypingNumber = [chat statusObjectForKey:WE_ARE_TYPING];
		AITypingState   previousTypingState = (previousTypingNumber ? [previousTypingNumber intValue] : AINotTyping);
		AITypingState   currentTypingState;

		enteredTextTimer = [chat statusObjectForKey:ENTERED_TEXT_TIMER];
		
		//Determine if this change indicated the user was typing or indicated the user had no longer entered text
		if([[inTextEntryView attributedString] length] != 0){ //User is typing

			currentTypingState = AITyping;

			if(enteredTextTimer){
				[self _resetTypingTimer:enteredTextTimer forChat:chat];
			}else{
				[self _addTypingTimerForChat:chat];
			}

		}else{ //User is not typing
			currentTypingState = AINotTyping;
			[self _removeTypingTimer:enteredTextTimer forChat:chat];
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
					   forKey:KEY_TEMP_SUPPRESS_TYPING_NOTIFICATIONS
					   notify:NotifyNever];
		
		//Clear the flag after a short delay
		[self performSelector:@selector(_removeSuppressFlagFromChat:) withObject:chat afterDelay:0.0000001];
	}
}

/*
 * @brief Remove the typing suppression for a chat
 */
- (void)_removeSuppressFlagFromChat:(AIChat *)chat
{
	[chat setStatusObject:nil
				   forKey:KEY_TEMP_SUPPRESS_TYPING_NOTIFICATIONS
				   notify:NotifyNever];
}

//Typing state ---------------------------------------------------------------------------------------------------------
/*
 * @brief Send an AIContentTyping object for an AITypingState on a given chat
 */
- (void)_sendTypingState:(AITypingState)typingState toChat:(AIChat *)chat
{
	if([chat sendTypingNotifications] ||
	   ([chat integerStatusObjectForKey:WE_ARE_TYPING] != AINotTyping && typingState == AINotTyping)){ //We need this to allow 'stop typing' changes incase the user turns off the preference while they're typing
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

/*
 * @brief Switch the typing state to AIEnteredText
 *
 * Called after a timeout when the user has entered text but is not actively typing
 *
 * @param inTimer An NSTimer whose userInfo is an AIChat
 */
- (void)_switchToEnteredText:(NSTimer *)inTimer
{
	AIChat  *chat = [inTimer userInfo];
	[self _sendTypingState:AIEnteredText toChat:chat];
	[self _removeTypingTimer:[chat statusObjectForKey:ENTERED_TEXT_TIMER] forChat:chat];
}


//Typing timer ---------------------------------------------------------------------------------------------------------
/*
 * @brief Add the timer responsible for detecting when the user stops typing
 */
- (void)_addTypingTimerForChat:(AIChat *)chat
{
	NSTimer	*enteredTextTimer = [NSTimer scheduledTimerWithTimeInterval:ENTERED_TEXT_INTERVAL
																 target:self
															   selector:@selector(_switchToEnteredText:)
															   userInfo:chat
																repeats:NO];
	[chat setStatusObject:enteredTextTimer forKey:ENTERED_TEXT_TIMER notify:NotifyNever];
}

/*
 * @brief Reset the timer responsible for detecting when the user stops typing
 *
 * This is done because it is cheaper than removing the old timer and adding a new one
 */
- (void)_resetTypingTimer:(NSTimer *)enteredTextTimer forChat:(AIChat *)chat
{
	[enteredTextTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:ENTERED_TEXT_INTERVAL]];
}

/*
 * @brief Remove the timer responsible for detecting when the user stops typing
 */
- (void)_removeTypingTimer:(NSTimer *)enteredTextTimer forChat:(AIChat *)chat
{
	[enteredTextTimer invalidate];
	[chat setStatusObject:nil forKey:ENTERED_TEXT_TIMER notify:NotifyNever];
}

@end
