//
//  ESiTunesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 6/11/05.

/* Thanks to GrowlTunes from the Growl project for demonstrating how to receive notifications when 
 * the iTunes track changes.
 */

#import "ESiTunesPlugin.h"
#import "AIContentController.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define ITUNES_MINIMUM_VERSION 4.6f

#define	KEY_PLAYING			@"Playing"
#define	KEY_STOPPED			@"Stopped"

#define ALBUM_TRIGGER		AILocalizedString(@"%_album","Trigger for the album of the currently playing iTunes song")
#define ARTIST_TRIGGER		AILocalizedString(@"%_artist","Trigger for the artist of the currently playing iTunes song")
#define COMPOSER_TRIGGER	AILocalizedString(@"%_composer","Trigger for the composer of the currently playing iTunes song")
#define GENRE_TRIGGER		AILocalizedString(@"%_genre","Trigger for the genre of the currently playing iTunes song")
#define STATUS_TRIGGER		AILocalizedString(@"%_status","Trigger for the genre of the currently playing iTunes song")
#define TRACK_TRIGGER		AILocalizedString(@"%_track","Trigger for the name of the currently playing iTunes song")
#define	STORE_URL_TRIGGER	AILocalizedString(@"%_iTMS","Trigger for an iTunes Music Store link to the currently playing iTunes song")
#define MUSIC_TRIGGER		AILocalizedString(@"/music","Command which triggers *is listening to %_track by %_artist*")

/*!
 * @class ESiTunesPlugin
 * @brief Fiiltering component to provide triggers which are replaced by information from the current iTunes track
 */
@implementation ESiTunesPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	NSString *itunesPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
	if ([[[NSBundle bundleWithPath:itunesPath] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue] > ITUNES_MINIMUM_VERSION) {
		//Perform substitutions on outgoing content
		[[adium contentController] registerContentFilter:self 
												  ofType:AIFilterContent
											   direction:AIFilterOutgoing
												threaded:NO];

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(iTunesUpdate:)
																name:@"com.apple.iTunes.playerInfo"
															  object:nil];
		
		substitutionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"Album", ALBUM_TRIGGER,
			@"Artist", ARTIST_TRIGGER,
//			@"Comment", @"%_comment", /* ?? */
			@"Composer", COMPOSER_TRIGGER,
			@"Genre", GENRE_TRIGGER,
//			@"Play Count", @"%_playcount", /* ?? */
//			@"Rating", @"%_rating", /* ?? */
			@"Player State", STATUS_TRIGGER,
			@"Name", TRACK_TRIGGER,
			@"Store URL", STORE_URL_TRIGGER,
/*			@"Year", @"%_year", */
			nil];
		
		NSDictionary	*slashMusicDict;
		NSDictionary	*conditionalArtistTrackDict;
		
		slashMusicDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			AILocalizedString(@"*is listening to %_track by %_artist*","Phrase sent in response to /music.  %_track and %_artist MUST match their localized forms for this to work properly."),
			KEY_PLAYING,
			AILocalizedString(@"*is listening to nothing*","Phrase sent in response to /music when nothing is playing."),
			KEY_STOPPED,
			nil];
		
		conditionalArtistTrackDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			AILocalizedString(@"%_track - %_artist","Phrase for the Current iTunes Track status. %_track and %_artist MUST match their localized forms for this to work properly."),
			KEY_PLAYING,
			@"",
			KEY_STOPPED,
			nil];
		
		phraseSubstitutionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			slashMusicDict,
			MUSIC_TRIGGER,
			conditionalArtistTrackDict,
			@"/currentITunesTrack", /* not localized since only used internally */
			nil];
		
		[slashMusicDict release];
		[conditionalArtistTrackDict release];
	}
}

/*
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	
}

/*!
* @brief Filter messages for keywords to replace
 *
 * Replace any iTunes triggers with the appropriate information
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *filteredMessage = nil;
	NSString					*stringMessage;
	
	if ((stringMessage = [inAttributedString string])) {
		NSEnumerator	*enumerator;
		NSString		*trigger;
		
		// Perform phrase substitutions, which change based on the current playstate
		enumerator = [phraseSubstitutionDict keyEnumerator];
		while ((trigger = [enumerator nextObject])) {
			if (([stringMessage rangeOfString:trigger options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				NSDictionary	*replacementDict;
				NSString		*replacement;
				NSString		*playerState;
				
				replacementDict = [phraseSubstitutionDict objectForKey:trigger];
				playerState = [iTunesCurrentInfo objectForKey:@"Player State"];
				
				//Determine the appropriate replacement based on the player state
				if ([playerState isEqualToString:@"Playing"] || [playerState isEqualToString:@"Paused"]) {
					replacement = [replacementDict objectForKey:KEY_PLAYING];
				} else {
					replacement = [replacementDict objectForKey:KEY_STOPPED];					
				}
				
				if (!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
				
				//Perform the replacement
				[filteredMessage replaceOccurrencesOfString:trigger
												 withString:replacement
													options:NSLiteralSearch
													  range:NSMakeRange(0, [filteredMessage length])];
				
				//Update our string for the simple trigger replacement process
				stringMessage = [filteredMessage string];
			}
		}
		
		//Substitute simple triggers as appropriate
		enumerator = [substitutionDict keyEnumerator];
		while ((trigger = [enumerator nextObject])) {
			if (([stringMessage rangeOfString:trigger options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				NSString	*replacement;
				
				/* Look up the appropriate key for this trigger, then use that key to find the replacement in the
				 * current iTunes info.
				 */
				if (!(replacement = [iTunesCurrentInfo objectForKey:[substitutionDict objectForKey:trigger]])) {
					//If no replacement is found, replace the trigger with an empty string
					replacement = @"";
				}
				
				if (!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
				
				//Perform the replacement
				[filteredMessage replaceOccurrencesOfString:trigger
												 withString:replacement
													options:NSLiteralSearch
													  range:NSMakeRange(0, [filteredMessage length])];
			}
		}
	}

	return (filteredMessage ? filteredMessage : inAttributedString);
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

/*!
 * @brief The iTunes song changed
 *
 * Cache the information, and then requst an immediate update to dynamic content
 */
- (void)iTunesUpdate:(NSNotification *)aNotification
{
	NSDictionary	*newInfo = [aNotification userInfo];
	
	if (newInfo != iTunesCurrentInfo) {
		[iTunesCurrentInfo release];
		iTunesCurrentInfo = [[aNotification userInfo] retain];
		
		AILog(@"iTunesUpdate: %@",iTunesCurrentInfo);

		[[adium notificationCenter] postNotificationName:Adium_RequestImmediateDynamicContentUpdate
												  object:nil];
	}
}

@end
