
#import "AIWebKitMessageViewPlugin.h"
#import "AIWebKitMessageViewController.h"

@implementation AIWebKitMessageViewPlugin

- (void)installPlugin
{
    //Register ourself as a message view plugin
    [[adium interfaceController] registerMessageViewPlugin:self];
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat]);
}

@end
