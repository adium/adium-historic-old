//
//  GBiTunerPlugin.m
//  Adium XCode
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#import "GBiTunerPlugin.h"

#define ITUNER_DEFAULT_PREFS    @"iTunerDefaults"

@interface GBiTunerPlugin (PRIVATE)
- (NSString *) hashLookup:(NSString *)pattern  contentMessage:(AIContentMessage *)content;
@end

@implementation GBiTunerPlugin

//install plugin
- (void)installPlugin
{
    //NSLog(@"installing GBiTunerPlugin");
    
    //Register our default preferences
    //[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ITUNER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ITUNER];
    
    //Our preference view
    //preferences = [[GBiTunerPreferences preferencePane] retain];
    
    //Register us as a filter
    [[adium contentController] registerOutgoingContentFilter:self];
    
    //Build the dictionary
    //	Eventually This Dictionary will become mutable and be updated from a preference pane 
    hash = [[NSDictionary alloc] initWithObjectsAndKeys:@"$var$", @"%album", 
        @"$var$", @"%artist", 
        @"$var$", @"%album",
        @"$var$", @"%genre", 
        @"$var$", @"%year", 
        @"$var$", @"%rating",
        @"$var$", @"%track",
        @"$var$", @"%composer",
        @"$var$", @"%playlist",
        @"$var$", @"%status",
        @"$var$", @"%position",
        @"$var$", @"%playcount",
        nil];
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        AIContentMessage *inObj = (AIContentMessage *)inObject;
        
	NSMutableAttributedString *mesg = [[inObj message] mutableCopyWithZone:nil];
	
	NSString *pattern;
	NSString *replaceWith;
	
	NSEnumerator *enumerator = [hash keyEnumerator];
	
	NSRange range;
	int location;
	int length;
	
	while (pattern = [enumerator nextObject])
	{//This loop gets run for every key in the dictionary
            
            
	    if([(replaceWith = [hash objectForKey:pattern]) isEqualToString:@"$var$"])
	    {//if key is a var go find out what the replacement text should be
		replaceWith = [self hashLookup:pattern contentMessage:inObj];
	    }
            
	    //create a range...
	    //	The initial position doesn't make sense...it gets set to 0 in a few lines
	    // 	this is just to make things more dynamic in the do/while loop
	    range = NSMakeRange( (0 - [replaceWith length])    , [[mesg string] length]);
	    do
	    {//execute this loop until we don't see any more instances of the pattern
		location = range.location + [replaceWith length];
		length = [[mesg string] length] - location;
                
		//find the pattern in the message
		//	notice that the range gets moved to just behind the last replacement
		//	this is to prevent infinite loops 
		range = [[mesg string] rangeOfString:pattern options:nil range:(NSMakeRange(location, length))];
		
		if(range.location != NSNotFound)
		{//If pattern was found in string do the replacement
		    [mesg replaceCharactersInRange:range withString:replaceWith];
		}
	    }while( range.location != NSNotFound );
	}
        
	[inObj setMessage:mesg]; 
	[mesg release];
    }
}

- (NSString*) hashLookup:(NSString*)pattern contentMessage:(AIContentMessage *)content
{
    if([pattern isEqualToString:@"%album"])
    {
        NSAppleScript *albumScript;
        NSString *albumString;
        
        albumScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n set theAlbum to album of current track \n end tell \n return theAlbum as string"];
        albumString = [[NSString alloc] initWithString:[[albumScript executeAndReturnError:nil] stringValue]];
        
        [albumScript release];
        
        return albumString;
    }
    else if([pattern isEqualToString:@"%artist"])
    {
        NSAppleScript *artistScript;
        NSString *artistString;
        
        artistScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n set theArtist to artist of current track \n end tell \n return theArtist as string"];
        artistString = [[NSString alloc] initWithString:[[artistScript executeAndReturnError:nil] stringValue]];
        
        [artistScript release];
        
        return artistString;
    }
    else if([pattern isEqualToString:@"%genre"])
    {
        NSAppleScript *genreScript;
        NSString *genreString;
        
        genreScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n set theGenre to genre of current track \n end tell \n return theGenre as string"];
        genreString = [[NSString alloc] initWithString:[[genreScript executeAndReturnError:nil] stringValue]];
        
        [genreScript release];
        
        return genreString;
    }
    else if([pattern isEqualToString:@"%track"])
    {
        NSAppleScript *trackScript;
        NSString *trackString;
        
        trackScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n set theTrack to name of current track \n end tell \n return theTrack as string"];
        trackString = [[NSString alloc] initWithString:[[trackScript executeAndReturnError:nil] stringValue]];
        
        [trackScript release];
        
        return trackString;
    }
    else if([pattern isEqualToString:@"%year"])
    {
        NSAppleScript *yearScript;
        NSString *yearString;
        
        yearScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n  set theYear to year of current track \n end tell \n return theYear as string"];
        yearString = [[NSString alloc] initWithString:[[yearScript executeAndReturnError:nil] stringValue]];
        
        [yearScript release];
				    
        return yearString;
    } else if([pattern isEqualToString:@"%rating"]){
        NSAppleScript *ratingScript;
        NSString *ratingString;
        
        ratingScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n  set theRating to the rating of current track \n end tell \n return theRating & \"/5\" as string"];
        ratingString = [[NSString alloc] initWithString:[[ratingScript executeAndReturnError:nil] stringValue]];
        
        [ratingScript release];	
				    
        return ratingString;
    } else if([pattern isEqualToString:@"%composer"]){
        NSAppleScript *composerScript;
        NSString *composerString;
        
        composerScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n  set theComposer to the composer of current track \n end tell \n return theComposer as string"];
        composerString = [[NSString alloc] initWithString:[[composerScript executeAndReturnError:nil] stringValue]];
        
        [composerScript release];
        
        return composerString;
    } else if([pattern isEqualToString:@"%playlist"]){
	
    } else if([pattern isEqualToString:@"%status"]){
        NSAppleScript *statusScript;
        NSString *statusString;
        
        statusScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n  set theStatus to player state \n end tell \n return theStatus as string"];
        statusString = [[NSString alloc] initWithString:[[statusScript executeAndReturnError:nil] stringValue]];
        
        [statusScript release];	
				    
        return statusString;
    }  else if([pattern isEqualToString:@"%position"]){
        NSAppleScript *positionScript;
        NSString *positionString;
        
        positionScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n  set thePosition to player position \n end tell \n return thePosition div 60 & \":\" & thePosition mod 60 as string"];
        positionString = [[NSString alloc] initWithString:[[positionScript executeAndReturnError:nil] stringValue]];
        
        [positionScript release];	
				    
        return positionString;
    } else if([pattern isEqualToString:@"%playcount"]){
        NSAppleScript *playCountScript;
        NSString *playCountString;
        
        playCountScript = [[NSAppleScript alloc] initWithSource:@"tell application \"iTunes\" \n  set thePlayCount to the played count of the current track \n end tell \n return thePlayCount as string"];
        playCountString = [[NSString alloc] initWithString:[[playCountScript executeAndReturnError:nil] stringValue]];
        
        [playCountScript release];	
				    
        return playCountString;
    }
    
    return pattern;
}

- (void) uninstallPlugin
{
    [hash release];
}

//Clean Up
- (void)dealloc
{    
    [super dealloc];
}

@end
