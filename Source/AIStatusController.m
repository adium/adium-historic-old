/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIStatusController.h"

//Localized status titles
#define STATUS_TITLE_AWAY		@"Away"
#define STATUS_TITLE_IDLE		@"Idle"
#define STATUS_TITLE_INVISIBLE	@"Invisible"
#define STATUS_TITLE_AVAILABLE	@"Available"

//Private idle function
extern double CGSSecondsSinceLastInputEvent(unsigned long evType);

@interface AIStatusController (PRIVATE)
- (void)_saveStateArrayAndNotifyOfChanges;
- (void)_applyStateToAllAccounts:(NSDictionary *)state;
- (void)_upgradeSavedAwaysToSavedStates;
- (void)_setMachineIsIdle:(BOOL)inIdle;
@end
									
/*!
 * @class AIStatusController
 * @brief Core status & state methods
 *
 * This class provides a foundation for Adium's status and state systems.
 */
@implementation AIStatusController

/*!
 * Init the status controller
 */
- (void)initController
{
	[self _setMachineIsIdle:NO];

}

/*!
 * Close the status controller
 */
- (void)closeController
{
	[stateArray release]; stateArray = nil;
	[activeState release]; activeState = nil;
}

/*!
 * @brief Access to Adium's user-defined states
 *
 * Returns an array of available user-defined states.  Each state is represented as a dictionary with the
 * following keys:
 *   STATE_TYPE 			   Should be "State", if not the entry should be ignored. 	(NSString)
 *   STATE_TITLE 			   Title for this away in the menu/list						(NSString)
 *   STATE_AWAY 			   User is away		 										(NSNumber - yes/no)
 *   STATE_AUTO_REPLY 		   Automatically reply to intial messages	 				(NSNumber - yes/no)
 *   STATE_AUTO_REPLY_IS_AWAY  Use AwayMessage instead of AutoReplyMessage to reply		(NSNumber - yes/no)
 *   STATE_AVAILABLE 		   User is available 										(NSNumber - yes/no)
 *   STATE_INVISIBLE 		   User is invisible 										(NSNumber - yes/no)
 *   STATE_IDLE 			   User is idle			 									(NSNumber - yes/no)
 *   STATE_IDLE_START 		   Starting idle duration 									(NSNumber - seconds)
 *   STATE_AWAY_MESSAGE 	   Away mesage 												(NSData - attributed string)
 *   STATE_AVAILABLE_MESSAGE   Available mesage 										(NSData - attributed string)
 *   STATE_AUTO_REPLY_MESSAGE  Auto-reply message 										(NSData - attributed string)
 */
- (NSArray *)stateArray
{
	if(!stateArray){
		//Load the preset states, defaulting to an empty array if none are available
		stateArray = [[[adium preferenceController] preferenceForKey:KEY_SAVED_STATUS
															   group:PREF_GROUP_SAVED_STATUS] mutableCopy];
		if(!stateArray) stateArray = [[NSMutableArray alloc] init];

		//Upgrade Adium 0.7x away messages
		[self _upgradeSavedAwaysToSavedStates];
	}

	return(stateArray);
}

/*!
 * @brief Returns an appropriate title for a state
 *
 * Not all states provide a title.  This method will generate an appropriate title based on the content of the passed
 * state.  If the passed state has a title, it will always be used.
 */ 
- (NSString *)titleForState:(NSDictionary *)state
{
	NSString	*title = nil;
	
	//If the state has a title, we simply use it
	if(!title){
		NSString *string = [state objectForKey:STATE_TITLE];
		if(string && [string length]) title = string;
	}
	
	//If the state is away, use the away message (Or "Away" if no message is provided)
	if(!title && [[state objectForKey:STATE_AWAY] boolValue]){
		NSString *string = [[NSAttributedString stringWithData:[state objectForKey:STATE_AWAY_MESSAGE]] string];
		if(string && [string length]){
			title = string;
		}else{
			title = STATUS_TITLE_AWAY;
		}
	}
	//If the state is available, use the avaiable message
	if(!title && [[state objectForKey:STATE_AVAILABLE] boolValue]){
		NSString *string = [[NSAttributedString stringWithData:[state objectForKey:STATE_AVAILABLE_MESSAGE]] string];
		if(string && [string length]) title = string;
	}
	//If the state is an auto-reply, use the auto-reply message
	if(!title && [[state objectForKey:STATE_AUTO_REPLY] boolValue]){
		NSString *string = [[NSAttributedString stringWithData:[state objectForKey:STATE_AUTO_REPLY_MESSAGE]] string];
		if(string && [string length]) title = string;
	}
	//If the state is simply idle, use the string "Idle"
	if(!title && [[state objectForKey:STATE_IDLE] boolValue]){
		title = STATUS_TITLE_IDLE;
	}
	//If the state is simply invisible, use the string "Invisible"
	if(!title && [[state objectForKey:STATE_INVISIBLE] boolValue]){
		title = STATUS_TITLE_INVISIBLE;
	}
	//If the state is none of the above, use the string "Available"
	if(!title) title = STATUS_TITLE_AVAILABLE;
	
	return(title);
}

/*!
 * @brief Returns an appropriate icon for a state
 *
 * This method will generate an appropriate status icon based on the content of the passed state.
 */ 
- (NSImage *)iconForState:(NSDictionary *)state
{
	NSString	*statusID;
	
	if([[state objectForKey:STATE_AWAY] boolValue]){
		statusID = @"away";
	}else if([[state objectForKey:STATE_IDLE] boolValue]){
		statusID = @"idle";
	}else{
		statusID = @"available";
	}
	
	return([AIStatusIcons statusIconForStatusID:statusID type:AIStatusIconList direction:AIIconNormal]);
}

/*!
 * @brief Set the active state
 *
 * Sets the currently active state.  This applies throughout Adium and to all accounts.  The state will become
 * effective immediately.  When the active state changes, an AIActiveStateChangedNotification is broadcast.
 */ 
- (void)setActiveState:(NSDictionary *)state
{
	if(activeState != state){
		[activeState release];
		activeState = [state retain];

		//Apply the state to our accounts and notify
		[self _applyStateToAllAccounts:activeState];
		[[adium notificationCenter] postNotificationName:AIActiveStateChangedNotification object:nil];
	}
}

/*!
 * @brief Retrieve active state
 *
 * Returns the currently active state.
 */ 
- (NSDictionary *)activeState
{
	return(activeState);
}

/*!
 * @brief Save changes to the state array and notify observers
 *
 * Saves any outstanding changes to the state array.  There should be no need to call this manually, since all the
 * state array modifying methods in this class call it automatically after making changes.
 *
 * After the state array is saved, observers are notified that is has changed.  Call after making any changes to the
 * state array from within the controller.
 */ 
- (void)_saveStateArrayAndNotifyOfChanges
{
	[[adium preferenceController] setPreference:stateArray
										 forKey:KEY_SAVED_STATUS
										  group:PREF_GROUP_SAVED_STATUS];
	[[adium notificationCenter] postNotificationName:AIStateArrayChangedNotification object:nil];
}

/*!
 * @brief Apply a state to all accounts
 *
 * Applies the passed state to all accounts, active and innactive.
 */ 
- (void)_applyStateToAllAccounts:(NSDictionary *)state
{
	AIPreferenceController	*controller = [adium preferenceController];
	NSData	*awayMessage, *availableMessage, *autoReplyMessage;
	BOOL 	available, away, autoReply, autoReplyIsAway, invisible, idle;
	int  	idleStart;
	
	//State Properties
	available = [[state objectForKey:STATE_AVAILABLE] boolValue];
	away = [[state objectForKey:STATE_AWAY] boolValue];
	autoReply = [[state objectForKey:STATE_AUTO_REPLY] boolValue];
	autoReplyIsAway = [[state objectForKey:STATE_AUTO_REPLY_IS_AWAY] boolValue];
	invisible = [[state objectForKey:STATE_INVISIBLE] boolValue];
	idle = [[state objectForKey:STATE_IDLE] boolValue];
	idleStart = [[state objectForKey:STATE_IDLE_START] intValue];	
	
	//Attributed Strings (In NSData form)
	awayMessage = [state objectForKey:STATE_AWAY_MESSAGE];
	availableMessage = [state objectForKey:STATE_AVAILABLE_MESSAGE];
	autoReplyMessage = [state objectForKey:STATE_AUTO_REPLY_MESSAGE];
	
	//Available Message
	if(available && availableMessage && [availableMessage length]){
		[controller setPreference:availableMessage forKey:STATUS_AVAILABLE_MESSAGE group:GROUP_ACCOUNT_STATUS];
	}else{
		[controller setPreference:nil forKey:STATUS_AVAILABLE_MESSAGE group:GROUP_ACCOUNT_STATUS];
	}
	
	//Away Message
	if(away && awayMessage && [awayMessage length]){
		[controller setPreference:awayMessage forKey:STATUS_AWAY_MESSAGE group:GROUP_ACCOUNT_STATUS];
	}else{
		[controller setPreference:nil forKey:STATUS_AWAY_MESSAGE group:GROUP_ACCOUNT_STATUS];
	}
	
	//Auto-Reply
	if(autoReplyIsAway) autoReplyMessage = awayMessage;
	if(autoReply && autoReplyMessage && [autoReplyMessage length]){
		[controller setPreference:autoReplyMessage forKey:STATUS_AUTO_REPLY group:GROUP_ACCOUNT_STATUS];
	}else{
		[controller setPreference:nil forKey:STATUS_AUTO_REPLY group:GROUP_ACCOUNT_STATUS];
	}
	
	//Idle
	if(idle){
		[controller setPreference:[NSDate dateWithTimeIntervalSinceNow:-(idleStart ? idleStart : 60)]
						   forKey:STATUS_IDLE_SINCE
							group:GROUP_ACCOUNT_STATUS];
	}else{
		[controller setPreference:nil forKey:STATUS_IDLE_SINCE group:GROUP_ACCOUNT_STATUS];
	}
	
	//Invisible
	if(invisible){
		[controller setPreference:[NSNumber numberWithBool:YES] forKey:STATUS_INVISIBLE group:GROUP_ACCOUNT_STATUS];
	}else{
		[controller setPreference:nil forKey:STATUS_INVISIBLE group:GROUP_ACCOUNT_STATUS];
		
	}
}

/*!
 * @brief Temporary upgrade code for 0.7x -> 0.8
 *
 * Versions 0.7x and prior stored their away messages in a different format.  This code allows a seamless
 * transition from 0.7x to 0.8.  We can easily recognize the old format because the away messages are of
 * type "Away" instead of type "State", which is used for all 0.8 and later saved states.
 * Since we are changing the array as we scan it, an enumerator will not work here.
 */
#define OLD_KEY_SAVED_AWAYS			@"Saved Away Messages"
#define OLD_GROUP_AWAY_MESSAGES		@"Away Messages"
#define OLD_STATE_SAVED_AWAY		@"Away"
#define OLD_STATE_AWAY				@"Message"
#define OLD_STATE_AUTO_REPLY		@"Autoresponse"
#define OLD_STATE_TITLE				@"Title"
- (void)_upgradeSavedAwaysToSavedStates
{
	NSArray	*savedAways = [[adium preferenceController] preferenceForKey:OLD_KEY_SAVED_AWAYS
																   group:OLD_GROUP_AWAY_MESSAGES];
	
	if(savedAways){
		NSEnumerator	*enumerator = [savedAways objectEnumerator];
		NSDictionary	*state;
		
		//Update all the away messages to states
		while(state = [enumerator nextObject]){
			if([[state objectForKey:STATE_TYPE] isEqualToString:OLD_STATE_SAVED_AWAY]){
				//Extract the away message information from this old record
				NSData		*awayMessage = [state objectForKey:OLD_STATE_AWAY];
				NSData		*autoReplyMessage = [state objectForKey:OLD_STATE_AUTO_REPLY];
				NSString	*title = [state objectForKey:OLD_STATE_TITLE];
				
				//Create the new-style "State" from this information
				state = [NSDictionary dictionaryWithObjectsAndKeys:
					STATE_SAVED_STATE, STATE_TYPE,
					(title ? title : @""), STATE_TITLE,
					[NSNumber numberWithBool:YES], STATE_AWAY,
					[NSNumber numberWithBool:YES], STATE_AUTO_REPLY,
					[NSNumber numberWithBool:(autoReplyMessage == nil)], STATE_AUTO_REPLY_IS_AWAY,
					[NSNumber numberWithBool:NO], STATE_INVISIBLE,
					[NSNumber numberWithBool:NO], STATE_AVAILABLE,
					[NSNumber numberWithBool:NO], STATE_IDLE,
					[NSNumber numberWithInt:600], STATE_IDLE_START,
					(awayMessage ? awayMessage : [NSData data]), STATE_AWAY_MESSAGE,
					(awayMessage ? awayMessage : [NSData data]), STATE_AVAILABLE_MESSAGE,
					(autoReplyMessage ? autoReplyMessage : [NSData data]), STATE_AUTO_REPLY_MESSAGE,
					nil];
				
				//Add the updated state to our state array
				[stateArray addObject:state];
			}
		}
		
		//Save these changes and delete the old aways so we don't need to do this again
		[self _saveStateArrayAndNotifyOfChanges];
		[[adium preferenceController] setPreference:nil
											 forKey:OLD_KEY_SAVED_AWAYS
											  group:OLD_GROUP_AWAY_MESSAGES];
	}
}


//State Editing --------------------------------------------------------------------------------------------------------
#pragma mark State Editing
/*!
 * @brief Add a state
 *
 * Add a new state to Adium's state array.
 * @param state NSDictionary of state keys and values to add
 */
- (void)addState:(NSDictionary *)state
{
	[stateArray addObject:state];
	[self _saveStateArrayAndNotifyOfChanges];
}

/*!
 * @brief Remove a state
 *
 * Remove a new state from Adium's state array.
 * @param state NSDictionary of state keys and values to remove
 */
- (void)removeState:(NSDictionary *)state
{
	[stateArray removeObject:state];
	[self _saveStateArrayAndNotifyOfChanges];
}

/*!
 * @brief Move a state
 *
 * Move a state that already exists in Adium's state array to another index
 * @param state NSDictionary of state keys and values to move
 * @param destIndex Destination index
 */
- (int)moveState:(NSDictionary *)state toIndex:(int)destIndex
{
    int sourceIndex = [stateArray indexOfObject:state];
    
    //Remove the state
    [state retain];
    [stateArray removeObject:state];
    
    //Re-insert the account
    if(destIndex > sourceIndex) destIndex -= 1;
    [stateArray insertObject:state atIndex:destIndex];
    [state release];
    
	[self _saveStateArrayAndNotifyOfChanges];
	
	return(destIndex);
}

/*!
 * @brief Replace a state
 *
 * Replace a state in Adium's state array with another state.
 * @param oldState NSDictionary state that is in Adium's state array
 * @param newState NSDictionary state to replace the oldState with
 */
- (void)replaceExistingState:(NSDictionary *)oldState withState:(NSDictionary *)newState
{
	int index = [stateArray indexOfObject:oldState];
	
	if(index >= 0 && index < [stateArray count]){
		[stateArray replaceObjectAtIndex:index withObject:newState];
	}
	
	[self _saveStateArrayAndNotifyOfChanges];
}


//Machine Activity -----------------------------------------------------------------------------------------------------
#define MACHINE_IDLE_THRESHOLD			30 	//30 seconds of inactivity is considered idle
#define MACHINE_ACTIVE_POLL_INTERVAL	30	//Poll every 60 seconds when the user is active
#define MACHINE_IDLE_POLL_INTERVAL		1	//Poll every second when the user is idle
/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle.  The machine is idle when there are no input
 * events from the user (such as mouse movement or keyboard input).  In addition to this method, the status controller
 * sends out notifications when the machine becomes idle, stays idle, and returns to an active state.
 */
- (double)currentMachineIdle
{
    double idleTime = CGSSecondsSinceLastInputEvent(-1);
		
	//On MDD Powermacs, the above function will return a large value when the machine is active (perhaps a -1?).
	//Here we check for that value and correctly return a 0 idle time.
	if(idleTime >= 18446744000.0) idleTime = 0.0; //18446744073.0 is the lowest I've seen on my MDD -ai
	
    return(idleTime);
}

/*!
 * @brief Timer that checkes for machine idle
 *
 * This timer periodically checks the machine for inactivity.  When the machine has been inactive for atleast
 * MACHINE_IDLE_THRESHOLD seconds, a notification is broadcast.
 *
 * When the machine is active, this timer is called infrequently.  It's not important to notice that the user went
 * idle immediately, so we relax our CPU usage while waiting for an idle state to begin.
 *
 * When the machine is idle, the timer is called frequently.  It's important to notice immediately when the user
 * returns.
 */
- (void)_idleCheckTimer:(NSTimer *)inTimer
{
	double	currentIdle = [self currentMachineIdle];

	if(machineIsIdle){
		if(currentIdle < lastSeenIdle){
			//If the machine is less idle than the last time we recorded, it means that activity has occured and the
			//user is no longer idle.
			[self _setMachineIsIdle:NO];
		}else{
			//Periodically broadcast a 'MachineIdleUpdate' notification
			[[adium notificationCenter] postNotificationName:AIMachineIdleUpdateNotification
													  object:nil
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithDouble:currentIdle], @"Duration",
														[NSDate dateWithTimeIntervalSinceNow:-currentIdle], @"IdleSince",
														nil]];
		}
	}else{
		//If machine inactivity is over the threshold, the user has gone idle.
		if(currentIdle > MACHINE_IDLE_THRESHOLD) [self _setMachineIsIdle:YES];
	}
	
	lastSeenIdle = currentIdle;
}

/*!
 * @brief Sets the machine as idle or not
 *
 * This internal method updates the frequency of our idle timer depending on whether the machine is considered
 * idle or not.  It also posts the AIMachineIsIdleNotification and AIMachineIsActiveNotification notifications
 * based on the passed idle state
 */
- (void)_setMachineIsIdle:(BOOL)inIdle
{
	machineIsIdle = inIdle;
	
	//Post the appropriate idle or active notification
	if(machineIsIdle){
		[[adium notificationCenter] postNotificationName:AIMachineIsIdleNotification object:nil];
	}else{
		[[adium notificationCenter] postNotificationName:AIMachineIsActiveNotification object:nil];
	}
	
	//Update our timer interval for either idle or active polling
	[idleTimer invalidate];
	[idleTimer release];
	idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(machineIsIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL)
												  target:self
												selector:@selector(_idleCheckTimer:)
												userInfo:nil
												 repeats:YES] retain];
}

@end
