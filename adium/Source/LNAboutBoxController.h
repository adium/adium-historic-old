#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "AILinkTextView.h"


@interface LNAboutBoxController : NSWindowController {

    IBOutlet	NSButton	*button_duckIcon;
    IBOutlet	NSTextField	*textField_buildDate;
    IBOutlet	AILinkTextView	*linkTextView_siteLink;


    AIAdium		*owner;
    int			numberOfDuckClicks;

}


+ (LNAboutBoxController *)aboutBoxControllerForOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;
- (IBAction)adiumDuckClicked:(id)sender;


@end
