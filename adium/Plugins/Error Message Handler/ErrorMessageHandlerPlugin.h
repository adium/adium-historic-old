#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class ErrorMessageWindowController;

@interface ErrorMessageHandlerPlugin : AIPlugin {
    NSString		*errorTitle;
    NSString		*errorDesc;
}

- (void)handleError;
@end
