#import "IdleTimeWindowController.h"

@implementation IdleTimeWindowController

//Create and return a contact list editor window controller
static IdleTimeWindowController *sharedInstance = nil;
+ (id)idleTimeWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:@"SetIdleTime" owner:inOwner];
    }

    return(sharedInstance);
}

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    owner = [inOwner retain];

    [super initWithWindowNibName:windowNibName owner:self];

    return(self);
}

- (void)windowDidLoad
{
    //Install our observers
    [[owner notificationCenter] addObserver:self
                                  selector:@selector(buildAccountsPopup)
                                      name:Account_PropertiesChanged
                                    object:nil];
    [[owner notificationCenter] addObserver:self
                                  selector:@selector(buildAccountsPopup)
                                      name:Account_StatusChanged
                                    object:nil];
    [[owner notificationCenter] addObserver:self
                                  selector:@selector(buildAccountsPopup)
                                      name:Account_ListChanged
                                    object:nil];
    [self buildAccountsPopup];
    [self configureControls:nil];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    //Close this shared instance
    [self autorelease];
    sharedInstance = nil;
    
    return(YES);
}

- (void)dealloc
{
    [owner release];
    [AIIdleTimePlugin release];
    [[owner notificationCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)buildAccountsPopup
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    NSString		*originalSelection;

    // store the current selection for later
    originalSelection = [NSString stringWithFormat: @"%@", [popUp_Accounts titleOfSelectedItem]];

    [popUp_Accounts removeAllItems];
    [popUp_Accounts setAutoenablesItems:FALSE];

    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
	// always add the account to the menu
	[popUp_Accounts addItemWithTitle:[account accountDescription]];

	// only set the item enabled if the account responds to "IdleTime"
        if([[account supportedStatusKeys] containsObject:@"IdleTime"]){
	    [[popUp_Accounts itemWithTitle:[account accountDescription]] setEnabled:TRUE];
        }else{
	    [[popUp_Accounts itemWithTitle:[account accountDescription]] setEnabled:FALSE];
	}
    }

    // reselect the old item if it's in the list
    [popUp_Accounts selectItemWithTitle: originalSelection];
    
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

        [[owner accountController] setStatusObject:[NSNumber numberWithDouble:t] forKey:@"IdleTime" account:theAccount];
        [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"IdleSetManually" account:theAccount];
	
    }else{
        [[owner accountController] setStatusObject:[NSNumber numberWithDouble:0] forKey:@"IdleTime" account:theAccount];
        [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"IdleSetManually" account:theAccount];
    }
}

@end
