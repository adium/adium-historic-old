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
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentAlbum" ofType:@"scpt"]],@"%_album",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentArtist" ofType:@"scpt"]],@"%_artist",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentGenre" ofType:@"scpt"]],@"%_genre",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentName" ofType:@"scpt"]],@"%_track",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentYear" ofType:@"scpt"]],@"%_year",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentRating" ofType:@"scpt"]],@"%_rating",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentComposer" ofType:@"scpt"]],@"%_composer",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentStatus" ofType:@"scpt"]],@"%_status",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentPosition" ofType:@"scpt"]],@"%_position",
        [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"getiTunesCurrentPlayCount" ofType:@"scpt"]],@"%_playcount",
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

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject
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

				if(!mesg) mesg = [[inAttributedString mutableCopy] autorelease];   

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
    
    NSURL *scriptURL = [scriptDict objectForKey:pattern];
    if (scriptURL){
        NSAppleScript   *script = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error: nil];
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
