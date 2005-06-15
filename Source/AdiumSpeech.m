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

#import "AdiumSpeech.h"
#import <Adium/SUSpeaker.h>

#define TEXT_TO_SPEAK				@"Text"
#define VOICE						@"Voice"
#define PITCH						@"Pitch"
#define RATE						@"Rate"

@implementation AdiumSpeech

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		speechArray = [[NSMutableArray alloc] init];
		resetNextTime = NO;
		speaking = NO;		
		
		[self loadVoiceArray];

	}
	
	return(self);
}

/*!
 * @brief Close
 */
- (void)dealloc
{
	[self _stopSpeakingNow];

	[speechArray release]; speechArray = nil;
	[voiceArray release]; voiceArray = nil;
	
	[super dealloc];
}


//Convenience method: speak the given text with default values
- (void)speakText:(NSString *)text
{
    [self speakText:text withVoice:nil pitch:0 rate:0];
}

//Speak a voice-specific sample text at the passed settings
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(int)rate
{		
	NSString	*demoText;	
	int			voiceIndex;
	SUSpeaker	*theSpeaker;
	
	[self _stopSpeakingNow];
	theSpeaker = [self _speakerForVoice:voiceString index:&voiceIndex];
	demoText = [theSpeaker demoTextForVoiceAtIndex:((voiceIndex != NSNotFound) ? voiceIndex : -1)];
	
	[self speakText:demoText
		  withVoice:voiceString
			  pitch:pitch
			   rate:rate];
}

//Return an array of voices in the same order as expected by SUSpeaker
- (NSArray *)voices
{
    return voiceArray;
}

//The systemwide default rate. This is cached when first used; it does not update if the systemwide default updates.
- (int)defaultRate
{
    [self initDefaultVoiceIfNecessary];
    return defaultRate;
}

//The systemwide default pitch. This is cached when first used; it does not update if the systemwide default updates.
- (int)defaultPitch
{ 
    [self initDefaultVoiceIfNecessary];
    return defaultPitch;
}

//add text & voiceString to the speech queue and attempt to speak text now
//pass voice as nil to use default voice
//pass pitch as 0 to use default pitch
//pass rate as 0 to use default rate
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(float)pitch rate:(float)rate
{
    if (text && [text length]) {
		if (!muteSounds) {
			NSMutableDictionary *dict;
			
			dict = [[NSMutableDictionary alloc] init];
			
			if (text) {
				[dict setObject:text forKey:TEXT_TO_SPEAK];
			}
			
			if (voiceString) [dict setObject:voiceString forKey:VOICE];			
			if (pitch > FLT_EPSILON) [dict setObject:[NSNumber numberWithFloat:pitch] forKey:PITCH];
			if (rate  > FLT_EPSILON) [dict setObject:[NSNumber numberWithFloat:rate]  forKey:RATE];
			
			[speechArray addObject:dict];
			[dict release];
			
			[self speakNext];
		}
    }
}

//attempt to speak the next item in the queue
- (void)speakNext
{
    //we have items left to speak and aren't already speaking
    if ([speechArray count] && !speaking) {
		//don't speak on top of other apps; instead, wait 1 second and try again
		if (SpeechBusySystemWide() > 0) {
			[self performSelector:@selector(speakNext)
					   withObject:nil
					   afterDelay:1.0];
			return;
		}
		
		speaking = YES;
		NSMutableDictionary *dict = [speechArray objectAtIndex:0];
		NSString 			*text = [dict objectForKey:TEXT_TO_SPEAK];
		NSNumber 			*pitchNumber = [dict objectForKey:PITCH];
		NSNumber 			*rateNumber = [dict objectForKey:RATE];
		SUSpeaker 			*theSpeaker = [self _speakerForVoice:[dict objectForKey:VOICE] index:NULL];
		
		[theSpeaker setPitch:(pitchNumber ? [pitchNumber floatValue] : defaultPitch)];
		[theSpeaker setRate:  (rateNumber ?  [rateNumber floatValue] : defaultRate)];
		
		[theSpeaker speakText:text];
		[speechArray removeObjectAtIndex:0];
    }
}

- (IBAction)didFinishSpeaking:(SUSpeaker *)theSpeaker
{
    speaking = NO;
    [self speakNext];
}

//Immediately stop speaking
- (void)_stopSpeakingNow
{
	[speaker_defaultVoice stopSpeaking];
	[speaker_variableVoice stopSpeaking];
}

//INitialize the default voice if it has not yet been done
- (void)initDefaultVoiceIfNecessary
{
    if (!speaker_defaultVoice) {
		speaker_defaultVoice = [[SUSpeaker alloc] init];
		[speaker_defaultVoice setDelegate:self];
		defaultRate = [speaker_defaultVoice rate];
		defaultPitch = [speaker_defaultVoice pitch];
    }
}

//Return the SUSpeaker which should be used for a given voice name, configured for that voice. Optionally, return
//the index of that voice in our array by reference.
- (SUSpeaker *)_speakerForVoice:(NSString *)voiceString index:(int *)voiceIndex;
{
	int theIndex = (voiceIndex ? *voiceIndex : 0);
	SUSpeaker	*theSpeaker;
	
	if (voiceString) {
		theIndex = [voiceArray indexOfObject:voiceString];
	} else {
		theIndex = NSNotFound;
	}
	
	if (theIndex != NSNotFound) {
		if (!speaker_variableVoice) { //initVariableVoiceifNecessary
			speaker_variableVoice = [[SUSpeaker alloc] init];
			[speaker_variableVoice setDelegate:self];
		}
		theSpeaker = speaker_variableVoice;
		[theSpeaker setVoice:theIndex];
		
	} else {
		[self initDefaultVoiceIfNecessary];
		theSpeaker = speaker_defaultVoice;
	}
	
	if (voiceIndex) *voiceIndex = theIndex;
	
	return theSpeaker;
}

- (void)loadVoiceArray
{
	NSArray			*originalVoiceArray = [SUSpeaker voiceNames];
	NSMutableArray	*ourVoiceArray = [originalVoiceArray mutableCopy];
	int messedUpIndex;
	
	//Vicki, a new voice in 10.3, returns an invalid name to SUSpeaker, Vicki3Smallurrent. If we see that name,
	//replace it with just Vicki.  If this gets fixed in a future release of OS X, this code will simply do nothing.
	messedUpIndex = [ourVoiceArray indexOfObject:@"Vicki3Smallurrent"];
	if (messedUpIndex != NSNotFound) {
		[ourVoiceArray replaceObjectAtIndex:messedUpIndex
								 withObject:@"Vicki"];
	}
	
	//ourVoiceArray is retained, so just assign it
    voiceArray = ourVoiceArray;  //voiceArray will be in the same order that SUSpeaker expects
}

@end
