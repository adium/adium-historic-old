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
    //Dictionary of the scripts to be run for various keys
    scriptDict = [[NSDictionary alloc] initWithObjectsAndKeys:

        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n set theAlbum to album of current track \n end tell \n return theAlbum as string \n end if \n end tell",@"%_album",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n set theArtist to artist of current track \n end tell \n return theArtist as string \n end if \n end tell",@"%_artist",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n set theGenre to genre of current track \n end tell \n return theGenre as string \n end if \n end tell",@"%_genre",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n set theTrack to name of current track \n end tell \n return theTrack as string \n end if \n end tell",@"%_track",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n  set theYear to year of current track \n end tell \n return theYear as string \n end if \n end tell",@"%_year",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n  set theRating to the rating of current track \n end tell \n return theRating * 5 div 100 & \"/5\" as string \n end if \n end tell",@"%_rating",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n  set theComposer to the composer of current track \n end tell \n return theComposer as string \n end if \n end tell",@"%_composer",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n  set theStatus to player state \n end tell \n return theStatus as string \n end if \n end tell",@"%_status",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n  set thePosition to player position \n end tell \n return thePosition div 60 & \":\" & thePosition mod 60 as string \n end if \n end tell",@"%_position",
        @"tell application \"System Events\" \n if ((application processes whose (name is equal to \"iTunes\")) count) is greater than 0 then \n tell application \"iTunes\" \n  set thePlayCount to the played count of the current track \n end tell \n return thePlayCount as string \n end if \n end tell",@"%_playcount",
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

- (void) uninstallPlugin
{
    [scriptDict release];
}

//Clean Up
- (void)dealloc
{    
    [super dealloc];
}

@end
