#import "ErrorMessageHandlerPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import "ErrorMessageWindowController.h"


@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    NSNotificationCenter	*interfaceNotificationCenter;
    //Install our observers
    interfaceNotificationCenter = [[owner interfaceController] interfaceNotificationCenter];
    [interfaceNotificationCenter addObserver:self selector:@selector(handleError) name:Interface_ErrorMessageRecieved object:nil];
}

- (void)handleError
{
    errorTitle = [[owner interfaceController] errorTitle];
    errorDesc = [[owner interfaceController] errorDesc];
    
    NSLog([NSString stringWithFormat:@"ERROR: %@ (%@)",errorTitle,errorDesc]);

    [[ErrorMessageWindowController ErrorMessageWindowControllerWithOwner:owner] displayError:errorTitle withDescription:errorDesc];
}

@end
