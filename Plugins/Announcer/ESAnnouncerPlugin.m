//
//  ESAnnouncerPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESAnnouncerPlugin.h"
#import "ESAnnouncerSpeakTextAlertDetailPane.h"
#import "ESAnnouncerSpeakEventAlertDetailPane.h"

#define	CONTACT_ANNOUNCER_NIB		@"ContactAnnouncer"		//Filename of the announcer info view
#define ANNOUNCER_ALERT_SHORT		AILocalizedString(@"Speak Specific Text",nil)
#define ANNOUNCER_ALERT_LONG		AILocalizedString(@"Speak the text \"%@\"",nil)

#define	ANNOUNCER_EVENT_ALERT_SHORT	AILocalizedString(@"Speak Event","short phrase for the contact alert which speaks the event")
#define	ANNOUNCER_EVENT_ALERT_LONG	AILocalizedString(@"Speak the event aloud","short phrase for the contact alert which speaks the event")

@implementation ESAnnouncerPlugin

- (void)installPlugin
{
    //Install our contact alerts
	[[adium contactAlertsController] registerActionID:SPEAK_TEXT_ALERT_IDENTIFIER
										  withHandler:self];
	[[adium contactAlertsController] registerActionID:SPEAK_EVENT_ALERT_IDENTIFIER
										  withHandler:self];
    
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_ANNOUNCER];
	
    //Install the contact info view
/*
	[NSBundle loadNibNamed:CONTACT_ANNOUNCER_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Announcer" categoryName:@"None" view:view_contactAnnouncerInfoView delegate:self] retain];
    [[adium contactController] addContactInfoView:contactView];
    [popUp_voice addItemsWithTitles:[[adium soundController] voices]];
 */
    lastSenderString = nil;
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
//    [[adium contactAlertsController] unregisterContactAlertProvider:self];
    
}

#pragma mark Contact specific preferences
- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSString	*voice = nil;
    NSNumber	*pitchNumber = nil;
    NSNumber	*rateNumber = nil;
	
    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];
    voice = [activeListObject preferenceForKey:KEY_VOICE_STRING group:PREF_GROUP_ANNOUNCER  ignoreInheritedValues:YES];
    if(voice) {
        [popUp_voice selectItemWithTitle:voice];
    } else {
        [popUp_voice selectItemAtIndex:0]; //"Default"
    }
	
    pitchNumber = [activeListObject preferenceForKey:KEY_PITCH group:PREF_GROUP_ANNOUNCER ignoreInheritedValues:YES];
    if(pitchNumber) {
		[slider_pitch setFloatValue:[pitchNumber floatValue]];
    } else {
		[slider_pitch setFloatValue:[[adium soundController] defaultPitch]];
    }
	
    rateNumber = [activeListObject preferenceForKey:KEY_RATE group:PREF_GROUP_ANNOUNCER ignoreInheritedValues:YES];
    if(rateNumber) {
		[slider_rate setIntValue:[rateNumber intValue]];
    } else {
		[slider_rate setIntValue:[[adium soundController] defaultRate]];
    }
}

- (IBAction)changedSetting:(id)sender
{
    if (sender == popUp_voice) {
		NSString * voice = [popUp_voice titleOfSelectedItem];
		if ([voice isEqualToString:@"Default"]){
			voice = nil;
		}
		[activeListObject setPreference:voice forKey:KEY_VOICE_STRING group:PREF_GROUP_ANNOUNCER];
    } else if (sender == slider_pitch) {
        [activeListObject setPreference:[NSNumber numberWithFloat:[slider_pitch floatValue]] forKey:KEY_PITCH group:PREF_GROUP_ANNOUNCER];
    } else if (sender == slider_rate) {
        [activeListObject setPreference:[NSNumber numberWithInt:[slider_rate intValue]] forKey:KEY_RATE group:PREF_GROUP_ANNOUNCER];
    }
}

//Speak Text Alert -----------------------------------------------------------------------------------------------------
#pragma mark Speak Text Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	if([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]){
		return(ANNOUNCER_ALERT_SHORT);
	}else{ /*Speak Event*/
		return(ANNOUNCER_EVENT_ALERT_SHORT);
	}
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	if([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]){		
		NSString *textToSpeak = [details objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
		
		if(textToSpeak && [textToSpeak length]){
			return([NSString stringWithFormat:ANNOUNCER_ALERT_LONG, textToSpeak]);
		}else{
			return(ANNOUNCER_ALERT_SHORT);
		}
	}else{ /*Speak Event*/
		return(ANNOUNCER_EVENT_ALERT_LONG);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"AnnouncerAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	if([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]){
		return([ESAnnouncerSpeakTextAlertDetailPane actionDetailsPane]);
	}else{ /*Speak Event*/
		return([ESAnnouncerSpeakEventAlertDetailPane actionDetailsPane]);
	}
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSString			*textToSpeak = nil;
	NSString			*timeFormat;

	BOOL				speakTime = [[details objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	BOOL				speakSender = [[details objectForKey:KEY_ANNOUNCER_SENDER] boolValue];
	
	timeFormat = (speakTime ?
				  [NSDateFormatter localizedDateFormatStringShowingSeconds:YES showingAMorPM:NO] :
				  nil);
	
	if([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]){
		NSString	*userText = [details objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];

		if(timeFormat){
			NSString	*timeString;
			
			timeString = [NSString stringWithFormat:@"%@... ",[[NSDate date] descriptionWithCalendarFormat:timeFormat
																								  timeZone:nil
																									locale:nil]];
			textToSpeak = (userText ? [timeString stringByAppendingString:userText] : textToSpeak);
		}else{
			textToSpeak = userText;
		}

		//Clear out the lastSenderString so the next speech event will get tagged with the sender's name
		[lastSenderString release]; lastSenderString = nil;
		
	}else{ /*Speak Event*/	
		
		//Handle messages in a custom manner
		if([[self class] customEventSpeechHandlingForEventID:eventID]){
			AIContentMessage	*content = [userInfo objectForKey:@"AIContentObject"];
			NSString			*message = [[[content message] safeString] string];
			AIListObject		*source = [content source];
			BOOL				isOutgoing = [content isOutgoing];
			BOOL				newParagraph = NO;
			NSMutableString		*theMessage = [NSMutableString string];
			
			if(speakSender && !isOutgoing) {
				NSString	*senderString;
				
				//Get the sender string
				senderString = [source displayName];
			
				//Don't repeat the same sender string for messages twice in a row
				if(!lastSenderString || ![senderString isEqualToString:lastSenderString]){
					NSMutableString		*senderStringToSpeak;
					
					//Track the sender string before modifications
					[lastSenderString release]; lastSenderString = [senderString retain];
					
					senderStringToSpeak = [senderString mutableCopy];
					
					 //deemphasize all words after first in sender's name, approximating human name pronunciation better
					[senderStringToSpeak replaceOccurrencesOfString:@" " 
														 withString:@" [[emph -]] " 
															options:NSCaseInsensitiveSearch
															  range:NSMakeRange(0, [senderStringToSpeak length])];
					 //emphasize first word in sender's name
					[theMessage appendFormat:@"[[emph +]] %@...",senderStringToSpeak];
					newParagraph = YES;
					
					[senderStringToSpeak release];
				}
			}
			
			//Append the date if desired, after the sender name if that was added
			if(timeFormat){
				[theMessage appendFormat:@" %@...",[[content date] descriptionWithCalendarFormat:timeFormat
																						timeZone:nil
																						  locale:nil]];
			}
			
			if(newParagraph) [theMessage appendFormat:@" [[pmod +1; pbas +1]]"];

			//Finally, append the actual message
			[theMessage appendFormat:@" %@",message];
			
			//theMessage is now the final string which will be passed to the speech engine
			textToSpeak = theMessage;

		}else{
			//All non-message events use the normal naturalLanguageDescription methods, optionally prepending
			//the time
			NSString	*eventDescription;
			
			eventDescription = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:eventID
																						  listObject:listObject
																							userInfo:userInfo
																					  includeSubject:YES];
			
			if(timeFormat){
				NSString	*timeString;
				
				timeString = [NSString stringWithFormat:@"%@... ",[[NSDate date] descriptionWithCalendarFormat:timeFormat
																									  timeZone:nil
																										locale:nil]];
				textToSpeak = [timeString stringByAppendingString:eventDescription];
			}else{
				textToSpeak = eventDescription;
			}
			
			//Clear out the lastSenderString so the next speech event will get tagged with the sender's name
			[lastSenderString release]; lastSenderString = nil;
		}
	}
	
	//Do the speech, with custom voice/pitch/rate as desired
	if(textToSpeak){
		NSString	*voice = nil;
		float		pitch = 0;
		int			rate = 0;
		
		//Retrieve custom settings for this listObject
		if(listObject){
			voice = [listObject preferenceForKey:KEY_VOICE_STRING group:PREF_GROUP_ANNOUNCER];			
			pitch = [[listObject preferenceForKey:KEY_PITCH group:PREF_GROUP_ANNOUNCER] floatValue];
			rate = [[listObject preferenceForKey:KEY_RATE group:PREF_GROUP_ANNOUNCER] intValue];
		}
		
		if(voice || pitch || rate){
			[[adium soundController] speakText:textToSpeak withVoice:voice andPitch:pitch andRate:rate];
		}else{
			[[adium soundController] speakText:textToSpeak];
		}
	}
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	if([actionID isEqualToString:SPEAK_TEXT_ALERT_IDENTIFIER]){
		return(YES);
	}else{ /*Speak Event*/
		return(NO);
	}
}

+ (BOOL)customEventSpeechHandlingForEventID:(NSString *)eventID
{
	return([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED] ||
		   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST] ||
		   [eventID isEqualToString:CONTENT_MESSAGE_SENT]);
}

@end
