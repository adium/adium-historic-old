#import "JabberAccountViewController.h"
#import "JabberAccount.h"

@interface JabberAccountViewController (PRIVATE)
- (id)initForAccount:(id)inAccount;
- (void)dealloc;
- (void)accountPropertiesChanged:(NSNotification *)notification;
- (void)initAccountView;
@end

@implementation JabberAccountViewController

+ (id)accountView
{
    return [[[self alloc] initForAccount:inAccount] autorelease];
}

- (NSView *)view
{
    return view_accountView;
}

//Save the changed properties
- (IBAction)preferenceChanged:(id)sender
{
    if (sender == textField_username) {
        [[adium accountController] setProperty: [sender stringValue]
                                        forKey: @"Username"
                                       account: account];
    } else if (sender == textField_host) {
        [[adium accountController] setProperty: [sender stringValue]
                                        forKey: @"Host"
                                       account: account];
    }
}

- (void)configureViewAfterLoad
{
    //highlight the username field
    [[[view_accountView superview] window] setInitialFirstResponder:textField_username];
}

- (NSArray *)auxiliaryTabs
{
    return nil;
}

/*******************/
/* PRIVATE METHODS */
/*******************/

- (id)initForAccount:(id)inAccount
{
    [super init];
    
    account = [inAccount retain];
    
    if([NSBundle loadNibNamed:@"JabberAccountView" owner:self]){
        [self initAccountView];
    }else{
        NSLog(@"couldn't load account view bundle");
    }
    
    [[adium notificationCenter] addObserver:self selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged object:account];
    [self accountPropertiesChanged:nil];
    
    [textField_username setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789+-._"] length:129 caseSensitive:NO errorMessage:@"Improper Format"]];

    [textField_host setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789-_."] length:129 caseSensitive:NO errorMessage:@"Improper Format"]];
    
    return self;
}

- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [view_accountView release];
    
    [account release];
    
    [super dealloc];
}

- (void)accountPropertiesChanged:(NSNotification *)notification
{
    if (notification != nil) {
        NSString *key = [[notification userInfo] objectForKey:@"Key"];
        if ([key compare:@"Online"] != 0)
            return;
    }

    BOOL	isOnline = [[[adium accountController] propertyForKey:@"Online" account:account] boolValue];

    //Dim unavailable controls
    [textField_username setEnabled:!isOnline];
    [textField_host     setEnabled:!isOnline];
}

- (void)initAccountView
{
    NSString *savedUsername;
    NSString *savedHost;
    
    //Username
    savedUsername = [[account properties] objectForKey:@"Username"];
    if(savedUsername != nil && [savedUsername length] != 0){
        [textField_username setStringValue:savedUsername];
    }else{
        [textField_username setStringValue:@""];
    }
    
    //Host
    savedHost = [[account properties] objectForKey:@"Host"];
    if(savedHost != nil && [savedHost length] != 0){
        [textField_host setStringValue:savedHost];
    }else{
        [textField_host setStringValue:@""];
    }
}
@end
