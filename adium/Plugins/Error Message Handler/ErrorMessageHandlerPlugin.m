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
    [[ErrorMessageWindowController ErrorMessageWindowControllerWithOwner:owner] displayError:errorTitle withDescription:errorDesc];
}

@end
