
@class JabberAccount;

@interface JabberAccountViewController : AIObject <AIAccountViewController>
{
    JabberAccount   *account;

    IBOutlet    NSView          *view_accountView;
    IBOutlet    NSTextField     *textField_username;
    IBOutlet    NSTextField     *textField_host;
}

+ (id)accountViewForAccount:(id)inAccount;
- (NSView *)view;
- (void)configureViewAfterLoad;
- (IBAction)preferenceChanged:(id)sender;

@end
