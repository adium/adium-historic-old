/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

//$Id: LNAboutBoxController.m,v 1.30 2004/03/11 04:33:28 adamiser Exp $

#import "LNAboutBoxController.h"

#define ABOUT_BOX_NIB			@"AboutBox"
#define	ADIUM_SITE_LINK			@"http://adium.sourceforge.net/"
#define ADIUM_LINK_TEXT			@"adium.sourceforge.net"
#define DIRECTORY_INTERNAL_RESOURCES    @"/Contents/Resources/Avatars"

@interface LNAboutBoxController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (BOOL)windowShouldClose:(id)sender;
- (void)_adiumDuckOptionClicked;
- (NSString *)_applicationVersion;
- (void)_loadBuildInformation;
- (NSArray *)_availableAvatars;
@end

@implementation LNAboutBoxController

//Returns the shared about box instance
LNAboutBoxController *sharedAboutBoxInstance = nil;
+ (LNAboutBoxController *)aboutBoxController
{
    if(!sharedAboutBoxInstance){
        sharedAboutBoxInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB];
    }
    return(sharedAboutBoxInstance);
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    numberOfDuckClicks = -1;
    
    return(self);
}

//Dealloc
- (void)dealloc
{    
    //[avatarArray release];
    [buildNumber release];
    [buildDate release];
    
    [super dealloc];
}

//Prepare the about box window
- (void)windowDidLoad
{
    NSAttributedString		*creditsString;
    
    //Load our build information and avatar list
    [self _loadBuildInformation];
    //avatarArray = [[self _availableAvatars] retain];

    //Credits
    creditsString = [[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits.rtf" ofType:nil] documentAttributes:nil] autorelease];
    [[textView_credits textStorage] setAttributedString:creditsString];
    [[textView_credits enclosingScrollView] setLineScroll:0.0];
    [[textView_credits enclosingScrollView] setPageScroll:0.0];
    
    //Start scrolling    
    scrollLocation = 0; 
    scrollRate = 1.0;
    maxScroll = [[textView_credits textStorage] size].height - [[textView_credits enclosingScrollView] documentVisibleRect].size.height;
    scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/20.0) target:self selector:@selector(scrollTimer:) userInfo:nil repeats:YES] retain];
    
    //Setup the build date / version
    [button_buildButton setTitle:buildDate];
    [textField_version setStringValue:[self _applicationVersion]];
    
    [[self window] center];
}

//Close the about box
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Cleanup as the window is closing
- (BOOL)windowShouldClose:(id)sender
{
    [sharedAboutBoxInstance autorelease]; sharedAboutBoxInstance = nil;
    [scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;

    return(YES);
}

//Scroll credits
- (void)scrollTimer:(NSTimer *)scrollTimer
{    
//    if([[textView_credits window] isMainWindow]){
		scrollLocation += scrollRate;
		
		if(scrollLocation > maxScroll) scrollLocation = 0;    
		if(scrollLocation < 0) scrollLocation = maxScroll;
		
		[textView_credits scrollPoint:NSMakePoint(0, scrollLocation)];
//    }
}

//Visit the Adium homepage
- (IBAction)visitHomepage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.adiumx.com"]];
}

//Flap or transition the duck when clicked
- (IBAction)adiumDuckClicked:(id)sender
{
    numberOfDuckClicks++;

    if([NSEvent optionKey]){
        [self _adiumDuckOptionClicked];
	
    }else{
        if(previousKeyWasOption){
            [button_duckIcon setImage:[AIImageUtilities imageNamed:@"Awake" forClass:[self class]]];
            [button_duckIcon setAlternateImage:[AIImageUtilities imageNamed:@"Flap" forClass:[self class]]];
            previousKeyWasOption = YES;
        }
        
        if(numberOfDuckClicks == 10/*[avatarArray count]*/){
            numberOfDuckClicks = -1;            
            [[adium soundController] playSoundNamed:@"/Adium.AdiumSoundset/Feather Ruffle.aif"];
        }else{
            [[adium soundController] playSoundNamed:@"/Adium.AdiumSoundset/Quack.aif"];
        }
    }
}

//Toggle build date/number display
- (IBAction)buildFieldClicked:(id)sender
{
    if((++numberOfBuildFieldClicks) % 2 == 0){
        [button_buildButton setTitle:buildDate];
    }else{
	[button_buildButton setTitle:buildNumber];
    }
}

//Receive the flags changed event for reversing the scroll direction via option
- (void)flagsChanged:(NSEvent *)theEvent
{
    if ([theEvent optionKey]) {
        scrollRate = -1.0;
    } else {
        scrollRate = 1.0;   
    }
}

//Transition the duck to a new avatar
- (void)_adiumDuckOptionClicked
{
/*    previousKeyWasOption = YES;
    [button_duckIcon setAlternateImage:nil];
    
    if(numberOfDuckClicks == [avatarArray count]){
        numberOfDuckClicks = -1;
        [button_duckIcon setImage:[AIImageUtilities imageNamed:@"Awake" forClass:[self class]]];
        [button_duckIcon setAlternateImage:nil];
        
        [[adium soundController] playSoundNamed:@"/Adium/Feather Ruffle.aif"];
        
    }else{

        [button_duckIcon setImage:[[[NSImage alloc] initWithContentsOfFile:[avatarArray objectAtIndex:numberOfDuckClicks]] autorelease]];

        [[adium soundController] playSoundNamed:@"/Aquatech/Ghost Hiss.aiff"];  
    }*/
}

//Returns the current version of Adium
- (NSString *)_applicationVersion
{
    NSDictionary    *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString	    *version = [infoDict objectForKey:@"CFBundleVersion"];

    return([NSString stringWithFormat:@"Adium %@",(version ? version : @"")]);
}

//Returns an array of available avatar filenames
- (NSArray *)_availableAvatars
{
    NSMutableArray	    *outArray = [NSMutableArray array];
    NSString		    *avatarPath;
    NSDirectoryEnumerator   *enumerator;
    NSString		    *avatarName;
    
    //Get the directory listing
    avatarPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_RESOURCES] stringByExpandingTildeInPath];
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:avatarPath];

    //Filter out any invalid
    while(avatarName = [enumerator nextObject]){
	if(![avatarName hasPrefix:@"."]){
	    [outArray addObject:[avatarPath stringByAppendingPathComponent:avatarName]];
	}
    }

    return(outArray);
}

//Load the current build date and our cryptic, non-sequential build number ;)
- (void)_loadBuildInformation
{
    //Grab the info from our buildnum script
    char *path, unixDate[256], num[256], whoami[256];
    if(path = (char *)[[[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil] fileSystemRepresentation])
    {
        FILE *f = fopen(path, "r");
        fscanf(f, "%s | %s | %s", num, unixDate, whoami);
        fclose(f);
	
        if(*num){
            buildNumber = [[NSString stringWithFormat:@"%s", num] retain];
	}
	
	if(*unixDate){
	    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" allowNaturalLanguage:NO] autorelease];
            NSDate	    *date;
	    
	    date = [NSDate dateWithTimeIntervalSince1970:[[NSString stringWithCString:unixDate] doubleValue]];
            buildDate = [[dateFormatter stringForObjectValue:date] retain];
	}
    }

    //Default to empty strings if something goes wrong
    if(!buildDate) buildDate = [@"" retain];
    if(!buildNumber) buildNumber = [@"" retain];
}

@end
