#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class ErrorMessageWindowController;

@interface ErrorMessageHandlerPlugin : AIPlugin {

}

- (void)handleError:(NSNotification *)notification;

@end
