#import "ErrorMessageHandlerPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import "ErrorMessageWindowController.h"


@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    NSNotificationCenter	*interfaceNotificationCenter;

    //Install our observers
    interfaceNotificationCenter = [[owner interfaceController] interfaceNotificationCenter];
    [interfaceNotificationCenter addObserver:self selector:@selector(handleError:) name:Interface_ErrorMessageRecieved object:nil];
}

- (void)uninstallPlugin
{
    [ErrorMessageWindowController closeSharedInstance]; //Close the error window
}

#warning testing new syncmail, this time with a directory with spaces
#warning it doesn't appear to be working at all anymore though.

- (void)handleError:(NSNotification *)notification
{
    NSDictionary	*userInfo;
    NSString		*errorTitle;
    NSString		*errorDesc;

    //Get the error info
    userInfo = [notification userInfo];
    errorTitle = [userInfo objectForKey:@"Title"];
    errorDesc = [userInfo objectForKey:@"Description"];;

    //Log to console
    NSLog([NSString stringWithFormat:@"ERROR: %@ (%@)",errorTitle,errorDesc]);

    //Display an alert
    [[ErrorMessageWindowController errorMessageWindowControllerWithOwner:owner] displayError:errorTitle withDescription:errorDesc];
}

@end
