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

#import "AdiumSound.h"
#import "AdiumSpeech.h"
#import "AdiumSoundSets.h"

@implementation AISoundController

- (id)init
{
	if ((self = [super init])) {
		adiumSound = [[AdiumSound alloc] init];
		adiumSpeech = [[AdiumSpeech alloc] init];
		adiumSoundSets = [[AdiumSoundSets alloc] init];
	}
	
	return self;
}

- (void)controllerDidLoad
{
	[adiumSound controllerDidLoad];
}

- (void)controllerWillClose
{
	[adiumSound dealloc]; adiumSound = nil;
	[adiumSpeech dealloc]; adiumSpeech = nil;
	[adiumSoundSets dealloc]; adiumSoundSets = nil;
}

//Sound
- (void)playSoundAtPath:(NSString *)inPath{
	[adiumSound playSoundAtPath:inPath];
}

//Speech
- (NSArray *)voices{
	return [adiumSpeech voices];
}
- (void)speakDemoTextForVoice:(NSString *)voiceString withPitch:(float)pitch andRate:(int)rate{
	[adiumSpeech speakDemoTextForVoice:voiceString withPitch:pitch andRate:rate];
}
- (float)defaultRate{
	return [adiumSpeech defaultRate];
}
- (float)defaultPitch{
	return [adiumSpeech defaultPitch];
}
- (void)speakText:(NSString *)text{
	[adiumSpeech speakText:text];
}
- (void)speakText:(NSString *)text withVoice:(NSString *)voiceString pitch:(float)pitch rate:(float)rate{
	[adiumSpeech speakText:text withVoice:voiceString pitch:pitch rate:rate];
}

//Soundsets
- (NSArray *)soundSets{
	return [adiumSoundSets soundSets];
}

@end
