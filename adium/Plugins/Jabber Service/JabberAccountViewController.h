
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
- (void)configureViewAfterLoad;
- (IBAction)preferenceChanged:(id)sender;

@end
