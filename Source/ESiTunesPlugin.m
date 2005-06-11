//
//  ESiTunesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 6/11/05.


/*
 Some code copyright (c) The Growl Project, 2004
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ESiTunesPlugin.h"
#import "AIContentController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>

#define ITUNES_MINIMUM_VERSION 4.6f

@implementation ESiTunesPlugin

static	NSDictionary	*substitutionDict = nil;

/*!
* @brief Install
 */
- (void)installPlugin
{
	NSString *itunesPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
	if ([[[NSBundle bundleWithPath:itunesPath] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue] > 4.6f) {
		//Perform substitutions on outgoing content
		[[adium contentController] registerContentFilter:self 
												  ofType:AIFilterContent
											   direction:AIFilterOutgoing
												threaded:NO];

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(songChanged:)
																name:@"com.apple.iTunes.playerInfo"
															  object:nil];
		
		substitutionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"Album", @"%_album",
			@"Artist", @"%_artist",
			@"Comment", @"%_comment", /* ?? */
			@"Composer", @"%_composer",
			@"Genre", @"%_genre",
			@"Play Count", @"%_playcount", /* ?? */
			@"Rating", @"%_rating", /* ?? */
			@"Player State", @"%_status",
			@"Name", @"%_track",
			@"Year", @"%_year",
			nil];
			/* missing iTMS, playcount, position, /music */
	}
}

- (void)uninstallPlugin
{
	
}

/*!
* @brief Filter messages for keywords to replace
 *
 * Replace any script keywords with the result of running the script (with arguments as appropriate)
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *filteredMessage = nil;
	NSString					*stringMessage;
	
	if ((stringMessage = [inAttributedString string])) {
		NSEnumerator	*triggerEnumerator;
		NSString		*trigger;
		
		//
		
		//Substitute simple triggers as appropriate
		triggerEnumerator = [substitutionDict keyEnumerator];
		while (trigger = [triggerEnumerator nextObject]) {
			if (([stringMessage rangeOfString:trigger options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				NSString	*iTunesReplacement;
				
				if (!(iTunesReplacement = [iTunesCurrentInfo objectForKey:trigger])) {
					iTunesReplacement = @"";
				}
				
				if (!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
				
				[filteredMessage replaceOccurrencesOfString:trigger
												 withString:iTunesReplacement
													options:NSLiteralSearch
													  range:NSMakeRange(0, [filteredMessage length])];
			}
		}
	}
	
	return filteredMessage;
}

/*!
* @brief Filter priority
 *
 * Filter earlier than the default
 */
- (float)filterPriority
{
	return HIGH_FILTER_PRIORITY;
}

- (void)songChanged:(NSNotification *)aNotification
{
	NSDictionary	*newInfo = [aNotification userInfo];
	
	if (newInfo != iTunesCurrentInfo) {
		[iTunesCurrentInfo release];
		iTunesCurrentInfo = [[aNotification userInfo] retain];
	}
}

#if 0
	NSString     *playerState = nil;
	iTunesState   newState    = itUNKNOWN;
	NSString     *newTrackURL = nil;
	NSDictionary *userInfo    = [aNotification userInfo];
	
	playerState = [[aNotification userInfo] objectForKey:@"Player State"];
	if ([playerState isEqualToString:@"Paused"]) {
		newState = itPAUSED;
	} else if ([playerState isEqualToString:@"Stopped"]) {
		newState = itSTOPPED;
	} else if ([playerState isEqualToString:@"Playing"]){
		newState = itPLAYING;
		/*For radios and files, the ID is the location.
		*For iTMS purchases, it's the Store URL.
		*For Rendezvous shares, we'll hash a compilation of a bunch of info.
		*/
		if ([userInfo objectForKey:@"Location"]) {
			newTrackURL = [userInfo objectForKey:@"Location"];
		} else if ([userInfo objectForKey:@"Store URL"]) {
			newTrackURL = [userInfo objectForKey:@"Store URL"];
		} else {
			/*Get all the info we can, in such a way that the empty fields are
			*	blank rather than (null).
			*Then we hash it and turn that into our identifier string.
			*That way a track name of "file://foo" won't confuse our code later on.
			*/
			NSArray *args = [userInfo objectsForKeys:
				[NSArray arrayWithObjects:@"Name", @"Artist", @"Album", @"Composer", @"Genre",
					@"Year",@"Track Number", @"Track Count", @"Disc Number", @"Disc Count",
					@"Total Time", nil]
									  notFoundMarker:@""];
			newTrackURL = [args componentsJoinedByString:@"|"];
			newTrackURL = [[NSNumber numberWithUnsignedLong:[newTrackURL hash]] stringValue];
		}
	}
	
	if (newTrackURL && ![newTrackURL isEqualToString:trackURL]) { // this is different from previous notification
		NSString		*track         = nil;
		NSString		*length        = nil;
		NSString		*artist        = @"";
		NSString		*album         = @"";
		BOOL			compilation    = NO;
		NSNumber		*rating        = nil;
		NSString		*ratingString  = nil;
		NSImage			*artwork       = nil;
		NSDictionary	*error         = nil;
		NSString		*displayString;
		
		if ([userInfo objectForKey:@"Artist"])
			artist = [userInfo objectForKey:@"Artist"];
		if ([userInfo objectForKey:@"Album"])
			album = [userInfo objectForKey:@"Album"];
		track = [userInfo objectForKey:@"Name"];
		
		length  = [userInfo objectForKey:@"Total Time"];
		// need to format a bit the length as it is returned in ms
		int sec  = [length intValue] / 1000;
		int hr  = sec/3600;
		sec -= 3600*hr;
		int min = sec/60;
		sec -= 60*min;
		if (hr > 0)
			length = [NSString stringWithFormat:@"%d:%02d:%02d", hr, min, sec];
		else
			length = [NSString stringWithFormat:@"%d:%02d", min, sec];
		
		compilation = ([userInfo objectForKey:@"Compilation"] != nil);

		rating = [userInfo objectForKey:@"Rating"];
	}
}

#endif

@end
