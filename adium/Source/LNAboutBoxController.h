#import "AILinkTextView.h"

@interface LNAboutBoxController : NSWindowController {

    IBOutlet	NSButton	*button_duckIcon;
    IBOutlet	NSButton	*button_buildButton;
    IBOutlet	AILinkTextView	*linkTextView_siteLink;

    NSMutableArray      *avatarArray;
    NSString 		*buildNumber, *buildDate;
    AIAdium		*owner;
    int			numberOfDuckClicks, numberOfBuildFieldClicks;
    BOOL		previousKeyWasOption;

}

+ (LNAboutBoxController *)aboutBoxControllerForOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;
- (IBAction)adiumDuckClicked:(id)sender;
- (IBAction)buildFieldClicked:(id)sender;

@end
