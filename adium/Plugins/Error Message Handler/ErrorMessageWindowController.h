#import <Cocoa/Cocoa.h>
#import "ErrorMessageHandlerPlugin.h"

@class AIInterfaceController;

@interface ErrorMessageWindowController : NSWindowController {

    IBOutlet	NSTextField	*textField_errorTitle;
    IBOutlet	NSTextField	*textField_errorInfo;

    IBOutlet	NSTabView	*tabView_multipleErrors;
    IBOutlet	NSTextField	*textField_errorCount;

    IBOutlet	NSButton	*button_okay;


    NSMutableArray	*errorTitleArray;
    NSMutableArray	*errorDescArray;

    AIAdium	*owner;
}

+ (id)ErrorMessageWindowControllerWithOwner:(id)inOwner;
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)displayError:(NSString *)inTitle withDescription:(NSString *)inDesc;
- (IBAction)okay:(id)sender;
- (IBAction)okayToAll:(id)sender;
- (void)refreshErrorDialog;
- (BOOL)shouldCascadeWindows;
- (IBAction)closeWindow:(id)sender;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;

@end
