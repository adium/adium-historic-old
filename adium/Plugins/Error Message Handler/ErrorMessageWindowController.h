#import <Cocoa/Cocoa.h>
#import "ErrorMessageHandlerPlugin.h"

@class AIInterfaceController;

@interface ErrorMessageWindowController : NSWindowController {

    IBOutlet	NSTextField	*textField_errorTitle;
    IBOutlet	NSTextView	*textView_errorInfo;
    IBOutlet	NSScrollView	*scrollView_errorInfo;

    IBOutlet	NSTabView	*tabView_multipleErrors;
    IBOutlet	NSTextField	*textField_errorCount;

    IBOutlet	NSButton	*button_okay;


    NSMutableArray	*errorTitleArray;
    NSMutableArray	*errorDescArray;

    AIAdium	*owner;
}

+ (id)errorMessageWindowControllerWithOwner:(id)inOwner;
+ (void)closeSharedInstance;
- (void)displayError:(NSString *)inTitle withDescription:(NSString *)inDesc;
- (IBAction)okay:(id)sender;
- (IBAction)okayToAll:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end
