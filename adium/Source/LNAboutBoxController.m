#import "LNAboutBoxController.h"
#import <AIUtilities/AIUtilities.h>


#define ABOUT_BOX_NIB		@"AboutBox"
#define	ADIUM_SITE_LINK		@"http://adium.sourceforge.net/"
#define ADIUM_LINK_TEXT		@"adium.sourceforge.net"

#define DIRECTORY_INTERNAL_RESOURCES    @"/Contents/Resources/Avatars"
@interface LNAboutBoxController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (BOOL)windowShouldClose:(id)sender;
- (void)_adiumDuckOptionClicked;
@end


@implementation LNAboutBoxController


LNAboutBoxController *sharedInstance = nil;


+ (LNAboutBoxController *)aboutBoxControllerForOwner:(id)inOwner
{

    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB owner:inOwner];
    }
    return(sharedInstance);
}



- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{

    numberOfDuckClicks = -1;

    [super initWithWindowNibName:windowNibName owner:self];

    owner = [inOwner retain];

    avatarArray = [[NSMutableArray alloc] init];
    
    return(self);
}


- (void)dealloc
{
    [owner release];

    [super dealloc];
}


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

    attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:ADIUM_SITE_LINK], NSLinkAttributeName,
        [NSFont cachedFontWithName:@"Lucida Grande" size:14], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        [NSNumber numberWithInt:1], NSUnderlineStyleAttributeName, nil];

    siteLink = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:ADIUM_LINK_TEXT] attributes: attributes];

    [[linkTextView_siteLink enclosingScrollView] setDrawsBackground:NO];
    [linkTextView_siteLink setDrawsBackground:NO];
    [linkTextView_siteLink setEditable:NO];
    [[linkTextView_siteLink textStorage] setAttributedString:siteLink];
    [linkTextView_siteLink resetCursorRects];

    [textField_buildDate setStringValue:[NSString stringWithFormat:@"Build Date: %s", __DATE__]];
    [textField_buildTime setStringValue:[NSString stringWithFormat:@"Build Time: %s", __TIME__]];

    [[self window] center];
}


- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}


- (BOOL)windowShouldClose:(id)sender
{
 
    [sharedInstance autorelease];
    sharedInstance = nil;

    return(YES);
}

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


- (void)_adiumDuckOptionClicked
{
    
    previousKeyWasOption = YES;
    [button_duckIcon setAlternateImage:nil];

    
    if (numberOfDuckClicks == [avatarArray count]) {
        numberOfDuckClicks = -1;
        [button_duckIcon setImage:[AIImageUtilities imageNamed:@"Awake" forClass:[self class]]];
        [button_duckIcon setAlternateImage:nil];
        
        [[owner soundController] playSoundNamed:@"/Adium/Feather Ruffle.aif"];
    }else{

        [button_duckIcon setImage:[[NSImage alloc] initWithContentsOfFile:[avatarArray objectAtIndex:numberOfDuckClicks]]];

        [[owner soundController] playSoundNamed:@"/Aquatech/Ghost Hiss.aiff"];  
    }
}


@end
