//
//  GBiTunerPlugin.m
//  Adium XCode
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#import "GBiTunerPlugin.h"
#import "GBiTunerPreferences.h"

#define ITUNES_IDENTIFIER		@"com.apple.iTunes"
#define APP_BUNDLE_IDENTIFIER	@"NSApplicationBundleIdentifier"



@interface GBiTunerPlugin (PRIVATE)
- (NSString *)hashLookup:(NSString *)pattern;
- (void)preferencesChanged:(NSNotification *)notification;
- (BOOL)iTunesIsOpen;
@end

@implementation GBiTunerPlugin

//install plugin
- (void)installPlugin
{
    //Dictionary of the scripts to be run for various keys\r
    scriptDict = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r set theAlbum to album of current track \r end tell \r return theAlbum as string \r end if",@"%_album",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r set theArtist to artist of current track \r end tell \r return theArtist as string \r end if",@"%_artist",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r set theGenre to genre of current track \r end tell \r return theGenre as string \r end if",@"%_genre",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r set theTrack to name of current track \r end tell \r return theTrack as string \r end if",@"%_track",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r  set theYear to year of current track \r end tell \r return theYear as string \r end if",@"%_year",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r  set theRating to the rating of current track \r end tell \r return theRating * 5 div 100 & \"/5\" as string \r end if",@"%_rating",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r  set theComposer to the composer of current track \r end tell \r return theComposer as string \r end if",@"%_composer",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r  set theStatus to player state \r end tell \r return theStatus as string \r end if",@"%_status",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r  set thePosition to player position \r end tell \r return thePosition div 60 & \":\" & thePosition mod 60 as string \r end if",@"%_position",
        @"tell application \"System Events\" \r set iTunes to ((application processes whose (name is equal to \"iTunes\")) count) \r end tell \r if iTunes is greater than 0 then \r tell application \"iTunes\" \r  set thePlayCount to the played count of the current track \r end tell \r return thePlayCount as string \r end if",@"%_playcount",
        nil];
    
    //Register us as a filter
//    [[adium contentController] registerOutgoingContentFilter:self];

    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ITUNER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ITUNER];
    
    //Our preference view
    preferences = [[GBiTunerPreferences preferencePane] retain];
    
    //watch preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //set up preferences initially
    [self preferencesChanged:nil];
    
}

//Update all views in response to a preference change
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ITUNER] == 0){
        
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ITUNER];
        
        if([[preferenceDict objectForKey:@"enabled"] boolValue]){
            //Register us as a filter
            [[adium contentController] registerOutgoingContentFilter:self];
        } else {
            //Unregister us as a filter
            [[adium contentController] unregisterOutgoingContentFilter:self];
        }
        
    }
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject
{
    NSMutableAttributedString   *mesg = nil;

    if(inAttributedString){
        NSString                    *originalAttributedString = [inAttributedString string];
		NSEnumerator                *enumerator = [scriptDict keyEnumerator];
        NSString                    *pattern;	
        
        //This loop gets run for every key in the dictionary
		while (pattern = [enumerator nextObject]){
            //if the original string contained this pattern
            if([originalAttributedString rangeOfString:pattern].location != NSNotFound){
				
                if(!mesg){
                    mesg = [[inAttributedString mutableCopyWithZone:nil] autorelease];
                }
                
                [mesg replaceOccurrencesOfString:pattern 
                                      withString:[self hashLookup:pattern] 
                                         options:NSLiteralSearch 
                                           range:NSMakeRange(0,[mesg length])];
            }
        }
    }
	
    return (mesg ? mesg : inAttributedString);
}

- (NSString*)hashLookup:(NSString*)pattern
{
    NSString        *returnString = nil;
    
    NSString *scriptString = [scriptDict objectForKey:pattern];
    if (scriptString){
        NSAppleScript   *script = [[NSAppleScript alloc] initWithSource:scriptString];
        returnString = [[script executeAndReturnError:nil] stringValue];
        [script release];
    }
 
    //@"" as the return string causes all sorts of problems because we can end up with a content message with no text
    //instead, turn a non-nil but zero-length returnString into a single space - this way, the pattern is still removed
    //but problems are avoided.
    if ((returnString && ([returnString length]==0)) || !returnString)
        returnString = @" ";
    
    return (returnString);	
}

- (void)uninstallPlugin
{
	//Unregister us as a filter
	[[adium contentController] unregisterOutgoingContentFilter:self];
	
    [scriptDict release]; scriptDict = nil;
}

@end
