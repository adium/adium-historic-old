#import "ErrorMessageHandlerPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import "ErrorMessageWindowController.h"


@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    //Install our observers
    [[owner notificationCenter] addObserver:self selector:@selector(handleError:) name:Interface_ErrorMessageReceived object:nil];
}

- (void)uninstallPlugin
{
    [ErrorMessageWindowController closeSharedInstance]; //Close the error window
}

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
