#import "IdleTimeWindowController.h"

@implementation IdleTimeWindowController

//Create and return a contact list editor window controller
static IdleTimeWindowController *sharedInstance = nil;
+ (id)IdleTimeWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:@"SetIdleTime" owner:inOwner];
    }

    return(sharedInstance);
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    owner = [inOwner retain];

    [super initWithWindowNibName:windowNibName owner:self];

    return(self);
}

- (void)windowDidLoad
{
    NSNotificationCenter	*accountNotificationCenter;
    //Install our observers
    accountNotificationCenter = [[owner accountController] accountNotificationCenter];
    [accountNotificationCenter addObserver:self
                                  selector:@selector(buildAccountsPopup)
                                      name:Account_PropertiesChanged
                                    object:nil];
    [accountNotificationCenter addObserver:self
                                  selector:@selector(buildAccountsPopup)
                                      name:Account_StatusChanged
                                    object:nil];
    [accountNotificationCenter addObserver:self
                                  selector:@selector(buildAccountsPopup)
                                      name:Account_ListChanged
                                    object:nil];
    [self buildAccountsPopup];
    [self configureControls:nil];
}

- (void)dealloc
{
    [owner release];
    [AIIdleTimePlugin release];

    [super dealloc];
}

- (void)buildAccountsPopup
{
    int		loop;
    NSArray	*accountArray;
    AIAccount	*theAccount;

    [popUp_Accounts removeAllItems];
    accountArray = [[owner accountController] accountArray];

    for(loop = 0;loop < [accountArray count];loop++){
        theAccount = [accountArray objectAtIndex:loop];
        if ([theAccount conformsToProtocol:@protocol(AIAccount_IdleTime)] && ([(AIAccount <AIAccount_Status> *)theAccount status]==STATUS_ONLINE)) {
            [popUp_Accounts addItemWithTitle:[theAccount accountDescription]];
        }
    }

    [self configureControls:nil];
}

- (IBAction)configureControls:(id)sender
{
    if ([popUp_Accounts numberOfItems]==0) [popUp_Accounts setEnabled:NO];
    else [popUp_Accounts setEnabled:YES];
    
    [checkBox_SetManually setEnabled:[popUp_Accounts isEnabled]];
    if (![checkBox_SetManually isEnabled]) [checkBox_SetManually setState:FALSE];
    [button_Apply setEnabled:[popUp_Accounts isEnabled]];
        
    [textField_IdleDays setEnabled:[checkBox_SetManually state]];
    [textField_IdleHours setEnabled:[checkBox_SetManually state]];
    [textField_IdleMinutes setEnabled:[checkBox_SetManually state]];
    [stepper_IdleDays setEnabled:[checkBox_SetManually state]];
    [stepper_IdleHours setEnabled:[checkBox_SetManually state]];
    [stepper_IdleMinutes setEnabled:[checkBox_SetManually state]];
}

- (IBAction)apply:(id)sender
{
    NSArray	*accountArray;
    AIAccount	*theAccount;

    accountArray = [[owner accountController] accountArray];
    theAccount = [accountArray objectAtIndex:[popUp_Accounts indexOfSelectedItem]];
    
    if([checkBox_SetManually state]){
        int d, h, m, t;
        d = [textField_IdleDays intValue];
        h = [textField_IdleHours intValue];
        m = [textField_IdleMinutes intValue];
        t = (d * 86400) + (h * 3600) + (m * 60);
        if ([theAccount conformsToProtocol:@protocol(AIAccount_IdleTime)])
        {
            [(AIAccount<AIAccount_IdleTime> *)theAccount setIdleTime:t manually:TRUE];
        }
    }else{
        if ([theAccount conformsToProtocol:@protocol(AIAccount_IdleTime)])
        {
            [(AIAccount<AIAccount_IdleTime> *)theAccount setIdleTime:0 manually:FALSE];
        }
    }
}

@end
