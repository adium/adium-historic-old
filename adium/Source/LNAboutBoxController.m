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

#import "LNAboutBoxController.h"

#define ABOUT_BOX_NIB			@"AboutBox"
#define	ADIUM_SITE_LINK			@"http://adium.sourceforge.net/"
#define ADIUM_LINK_TEXT			@"adium.sourceforge.net"
#define DIRECTORY_INTERNAL_RESOURCES    @"/Contents/Resources/Avatars"

@interface LNAboutBoxController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (BOOL)windowShouldClose:(id)sender;
- (void)_adiumDuckOptionClicked;
@end

@implementation LNAboutBoxController

//Returns the shared about box instance
LNAboutBoxController *sharedInstance = nil;
+ (LNAboutBoxController *)aboutBoxControllerForOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB owner:inOwner];
    }
    return(sharedInstance);
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    numberOfDuckClicks = -1;
    owner = [inOwner retain];
    
    buildDate = @"-1";
    buildNumber = @"-1";
    char *path, date[256], num[256];
    if(path = (char *)[[[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil] fileSystemRepresentation])
    {
        FILE *f = fopen(path, "r");
        fscanf(f, "%s | %s", num, date);
        fclose(f);
        if(*num)
            buildNumber = [[NSString stringWithFormat:@"Build Number: %s", num] retain];
        if(*date)
            buildDate = [[NSString stringWithFormat:@"Build Date: %s", date] retain];
    }
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [owner release];
    
    [avatarArray release];
    [buildNumber release];
    [buildDate release];
    
    [super dealloc];
}

//Prepare the about box window
- (void)windowDidLoad
{
    //Get the directory listing of avatars and put in the avatarArray
    NSString 	*avatarName;
    NSString 	*avatarPath;
    NSArray 	*avatarList;
    avatarArray = [[NSMutableArray alloc] init];
    avatarPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_RESOURCES] stringByExpandingTildeInPath];


    avatarList = [[NSFileManager defaultManager] directoryContentsAtPath:avatarPath];
    int loop;
    for(loop = 0;loop < [avatarList count];loop++){
        avatarName = [avatarList objectAtIndex:loop];
        [avatarArray addObject:[avatarPath stringByAppendingPathComponent:avatarName]];
    }

    //Set up the link
    NSAttributedString		*siteLink;
    NSMutableParagraphStyle	*paragraphStyle;
    NSDictionary		*attributes;

    paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setAlignment:NSCenterTextAlignment]; 

    attributes = [NSDictionary dictionaryWithObjectsAndKeys:ADIUM_SITE_LINK, NSLinkAttributeName,
        [NSFont cachedFontWithName:@"Lucida Grande" size:14], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        [NSNumber numberWithInt:1], NSUnderlineStyleAttributeName, nil];

    siteLink = [[NSAttributedString alloc] initWithString:ADIUM_LINK_TEXT attributes:attributes];

    [[linkTextView_siteLink enclosingScrollView] setDrawsBackground:NO];
    [linkTextView_siteLink setDrawsBackground:NO];
    [linkTextView_siteLink setEditable:NO];
    [linkTextView_siteLink setShowTooltip:NO];
    [[linkTextView_siteLink textStorage] setAttributedString:siteLink];
    [linkTextView_siteLink resetCursorRects];

    [siteLink release];

    [button_buildButton setTitle:buildDate];

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
    [sharedInstance autorelease]; sharedInstance = nil;

    return(YES);
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
        
        if(numberOfDuckClicks == [avatarArray count]){
            numberOfDuckClicks = -1;            
            [[owner soundController] playSoundNamed:@"/Adium/Feather Ruffle.aif"];
        }else{
            [[owner soundController] playSoundNamed:@"/Adium/Quack.aif"];
        }
    }
}

//Toggle build date/number display
- (IBAction)buildFieldClicked:(id)sender
{
    if((++numberOfBuildFieldClicks)%2 == 0)
        [button_buildButton setTitle:buildDate];
    else
        [button_buildButton setTitle:buildNumber];
}

//Transition the duck to a new avatar
- (void)_adiumDuckOptionClicked
{
    previousKeyWasOption = YES;
    [button_duckIcon setAlternateImage:nil];
    
    if(numberOfDuckClicks == [avatarArray count]){
        numberOfDuckClicks = -1;
        [button_duckIcon setImage:[AIImageUtilities imageNamed:@"Awake" forClass:[self class]]];
        [button_duckIcon setAlternateImage:nil];
        
        [[owner soundController] playSoundNamed:@"/Adium/Feather Ruffle.aif"];
        
    }else{

        [button_duckIcon setImage:[[[NSImage alloc] initWithContentsOfFile:[avatarArray objectAtIndex:numberOfDuckClicks]] autorelease]];

        [[owner soundController] playSoundNamed:@"/Aquatech/Ghost Hiss.aiff"];  
    }
}

@end
