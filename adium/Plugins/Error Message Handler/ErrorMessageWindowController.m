#import "ErrorMessageWindowController.h"


@implementation ErrorMessageWindowController

/* sharedInstance
*   returns the shared instance of AIErrorController
*/
static ErrorMessageWindowController *sharedInstance = nil;
+ (id)ErrorMessageWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:@"ErrorWindow" owner:inOwner];
    }

    return(sharedInstance);
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    owner = [inOwner retain];

    [super initWithWindowNibName:windowNibName owner:self];

    return(self);
}

- (void)dealloc
{
    [owner release];
    [ErrorMessageHandlerPlugin release];

    [super dealloc];
}

- (void)displayError:(NSString *)inTitle withDescription:(NSString *)inDesc
{
    //force the window to load
    [sharedInstance window];

    //add the error
    if([errorTitleArray count] < 20){ //Stop logging errors after 20
        [errorTitleArray insertObject:inTitle atIndex:0];
        [errorDescArray insertObject:inDesc atIndex:0];
    }

    [self refreshErrorDialog];
}

- (IBAction)okay:(id)sender
{
    if([errorTitleArray count] == 1){
        //--close the error dialog--
        [self closeWindow:nil];

    }else{
        //--remove the first error and display the next one--
        [errorTitleArray removeObjectAtIndex:0];
        [errorDescArray removeObjectAtIndex:0];

        [self refreshErrorDialog];
    }
}

- (IBAction)okayToAll:(id)sender
{
    //--close the error dialog--
    [self closeWindow:nil];
}

- (void)refreshErrorDialog
{
    NSRect	*oldFrame, *newFrame;
    
    //--Display the current error message--
    [textField_errorTitle setStringValue:[errorTitleArray objectAtIndex:0]];
    [textField_errorInfo setStringValue:[errorDescArray objectAtIndex:0]];

    //--Display the current error cont--
    if([errorTitleArray count] == 1){
        //--hide the 'okay all' button and error count--
        [tabView_multipleErrors selectTabViewItemAtIndex:0];

        //--set the button to 'okay'--
        [button_okay setTitle:@"Okay"];

        [[self window] setTitle:@"Adium : Error"];

    }else{
        //--show the 'okay all' button and error count--
        [tabView_multipleErrors selectTabViewItemAtIndex:1];

        [[self window] setTitle:[NSString stringWithFormat:@"Adium : Error (x%i)",[errorTitleArray count]]];

        //--set the button to 'next'--
        [button_okay setTitle:@"Next"];

    }

    //Resize the window bigger (if necessary) to fit the error message
//    oldFrame = [textField_errorInfo
    [textField_errorInfo sizeToFit];

    
    [self showWindow:nil];
}

/* shouldCascadeWindows
*   prevents the system from moving our window around
*/
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

/* closeWindow
*   closes this window
*/
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

/* windowDidLoad
*   called after the about window loads, so we can set up the window before it's displayed
*/
- (void)windowDidLoad
{
    errorTitleArray = [[NSMutableArray alloc] init];
    errorDescArray =  [[NSMutableArray alloc] init];
}

/* windowShouldClose
*   called as the window closes
*/
- (BOOL)windowShouldClose:(id)sender
{
    [errorTitleArray release]; errorTitleArray = nil;
    [errorDescArray release]; errorDescArray = nil;
    
    //--release the window controller (ourself)--
    sharedInstance = nil;
    [self autorelease];

    return(YES);
}

@end
