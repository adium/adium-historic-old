#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "JabberAccountViewController.h"
#import "JabberAccount.h"

@interface JabberAccountViewController (PRIVATE)
- (id)initForOwner:(id)inOwner account:(id)inAccount;
- (void)dealloc;
- (void)accountStatusChanged:(NSNotification *)notification;
- (void)initAccountView;
@end

@implementation JabberAccountViewController

+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount;
{
    return [[[self alloc] initForOwner:inOwner account:inAccount] autorelease];
}

- (NSView *)view
{
    return view_accountView;
}

//Save the changed properties
- (void)saveChanges
{
    [[account properties] setObject:[textField_username stringValue] forKey:@"Username"];
    [[account properties] setObject:[textField_host stringValue] forKey:@"Host"];

    //Broadcast a properties changed message
    [[owner notificationCenter] postNotificationName:Account_PropertiesChanged
                                                                         object:self
                                                                       userInfo:nil];
}

- (void)configureViewAfterLoad
{
    //highlight the username field
    [[[view_accountView superview] window] setInitialFirstResponder:textField_username];
}

/*******************/
/* PRIVATE METHODS */
/*******************/

- (id)initForOwner:(id)inOwner account:(id)inAccount
{
    [super init];
    
    owner = [inOwner retain];
    account = [inAccount retain];
    
    if([NSBundle loadNibNamed:@"JabberAccountView" owner:self]){
        [self initAccountView];
    }else{
        NSLog(@"couldn't load account view bundle");
    }
    
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:account];
    
    [textField_username setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789+-._"] length:129 caseSensitive:NO errorMessage:@"Improper Format"]];

    [textField_host setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789-_."] length:129 caseSensitive:NO errorMessage:@"Improper Format"]];
    
    return self;
}

- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self name:Account_StatusChanged object:account];
    
    [view_accountView release];
    
    [owner release];
    [account release];
    
    [super dealloc];
}

- (void)accountStatusChanged:(NSNotification *)notification
{
    BOOL	isOnline = [[[owner accountController] statusObjectForKey:@"Online" account:account] boolValue];

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
