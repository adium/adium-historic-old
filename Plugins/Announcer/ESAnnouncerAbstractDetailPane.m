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

#import "AIPreferenceController.h"
#import "AISoundController.h"
#import "ESAnnouncerAbstractDetailPane.h"
#import "ESAnnouncerPlugin.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AILocalizationButton.h>

@interface ESAnnouncerAbstractDetailPane (PRIVATE)
- (NSMenu *)voicesMenu;
@end

@implementation ESAnnouncerAbstractDetailPane
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[checkBox_speakEventTime setTitle:SPEAK_EVENT_TIME];
	[checkBox_speakContactName setTitle:AILocalizedString(@"Speak Name",nil)];
	[popUp_voices setMenu:[self voicesMenu]];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	BOOL		speakTime, speakContactName;
	NSString	*voice;
	NSNumber	*pitchNumber, *rateNumber;

	if(!inDetails) inDetails = [[adium preferenceController] preferenceForKey:[self defaultDetailsKey]
																		group:PREF_GROUP_ANNOUNCER];

	speakTime = [[inDetails objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	speakContactName = [[inDetails objectForKey:KEY_ANNOUNCER_SENDER] boolValue];

    if(voice = [inDetails objectForKey:KEY_VOICE_STRING]) {
        [popUp_voices selectItemWithTitle:voice];
    } else {
        [popUp_voices selectItemAtIndex:0]; //"Default"
    }
	
    if(pitchNumber = [inDetails objectForKey:KEY_PITCH]) {
		[slider_pitch setFloatValue:[pitchNumber floatValue]];
    } else {
		[slider_pitch setFloatValue:[[adium soundController] defaultPitch]];
    }
	
    if(rateNumber = [inDetails objectForKey:KEY_RATE]) {
		[slider_rate setIntValue:[rateNumber intValue]];
    } else {
		[slider_rate setIntValue:[[adium soundController] defaultRate]];
    }

	[checkBox_speakEventTime setState:speakTime];
	[checkBox_speakContactName setState:speakContactName];
}

- (void)configureForEventID:(NSString *)eventID listObject:(AIListObject *)inObject
{
	if([[adium contactAlertsController] isMessageEvent:eventID]){
		[checkBox_speakContactName setEnabled:YES];
	}else{
		[checkBox_speakContactName setEnabled:NO];
		[checkBox_speakContactName setState:NSOnState];
	}
}

//Should be overridden, with the subclass returning [self actionDetailsDromDict:actionDetails]
//where actionDetails is the dictionary of what it itself needs to store
- (NSDictionary *)actionDetails
{
	NSDictionary	*actionDetails = [self actionDetailsFromDict:nil];

	//Save the preferred settings for future use as defaults
	[[adium preferenceController] setPreference:actionDetails
										 forKey:[self defaultDetailsKey]
										  group:PREF_GROUP_ANNOUNCER];

	return(actionDetails);
}

- (NSDictionary *)actionDetailsFromDict:(NSMutableDictionary *)actionDetails
{
	NSNumber		*speakTime, *speakContactName, *pitch, *rate;
	NSString		*voice;

	if(!actionDetails) actionDetails = [NSMutableDictionary dictionary];

	speakTime = [NSNumber numberWithBool:([checkBox_speakEventTime state] == NSOnState)];
	speakContactName = [NSNumber numberWithBool:([checkBox_speakContactName state] == NSOnState)];

	voice = [[popUp_voices selectedItem] representedObject];	
	pitch = [NSNumber numberWithFloat:[slider_pitch floatValue]];
	rate = [NSNumber numberWithInt:[slider_rate intValue]];
	
	if(voice){
		[actionDetails setObject:voice
						  forKey:KEY_VOICE_STRING];
	}

	if([pitch floatValue] != [[adium soundController] defaultPitch]){
		[actionDetails setObject:pitch
						  forKey:KEY_PITCH];
	}
	
	if([rate intValue] != [[adium soundController] defaultRate]){
		[actionDetails setObject:rate
						  forKey:KEY_RATE];
	}
	[actionDetails setObject:speakTime
					  forKey:KEY_ANNOUNCER_TIME];
	[actionDetails setObject:speakContactName
					  forKey:KEY_ANNOUNCER_SENDER];
	
	return actionDetails;
}


- (NSString *)defaultDetailsKey
{
	return nil;
}

- (NSMenu *)voicesMenu
{
	NSArray			*voicesArray;
	NSMenu			*voicesMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem		*menuItem;
	NSEnumerator	*enumerator;
	NSString		*voice;
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Default",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[voicesMenu addItem:menuItem];
	[voicesMenu addItem:[NSMenuItem separatorItem]];

	voicesArray = [[[adium soundController] voices] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	enumerator = [voicesArray objectEnumerator];
	while(voice = [enumerator nextObject]){
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:voice
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:voice];
		[voicesMenu addItem:menuItem];
	}
	
	return(voicesMenu);
}

-(IBAction)changePreference:(id)sender
{
	//If the Default voice is selected, also set the pitch and rate to defaults
	if(sender == popUp_voices){
		if(![[popUp_voices selectedItem] representedObject]){
			[slider_pitch setFloatValue:[[adium soundController] defaultPitch]];
			[slider_rate setIntValue:[[adium soundController] defaultRate]];
		}
	}

	if(sender == popUp_voices ||
	   sender == slider_pitch ||
	   sender == slider_rate){
		[[adium soundController] speakDemoTextForVoice:[[popUp_voices selectedItem] representedObject]
											 withPitch:[slider_pitch floatValue]
											   andRate:[slider_rate intValue]];
	}
	[super changePreference:sender];
}
@end
