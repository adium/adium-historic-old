#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

@class JabberAccount;

@interface JabberAccountViewController : NSObject <AIAccountViewController>
{
    AIAdium         *owner;
    JabberAccount   *account;

    IBOutlet    NSView          *view_accountView;
    IBOutlet    NSTextField     *textField_username;
    IBOutlet    NSTextField     *textField_host;
}
+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount;
- (NSView *)view;
- (void)saveChanges;
- (void)configureViewAfterLoad;

@end
