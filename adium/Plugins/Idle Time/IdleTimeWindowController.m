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

    [accountPopup removeAllItems];
    accountArray = [[owner accountController] accountArray];

    for(loop = 0;loop < [accountArray count];loop++){
        theAccount = [accountArray objectAtIndex:loop];
        if ([theAccount conformsToProtocol:@protocol(AIAccount_IdleTime)] && ([(AIAccount <AIAccount_Status> *)theAccount status]==STATUS_ONLINE)) {
            [accountPopup addItemWithTitle:[theAccount accountDescription]];
        }
    }

    if ([accountPopup numberOfItems]==0) [accountPopup setEnabled:NO];
    else [accountPopup setEnabled:YES];
}

- (IBAction)setIdle:(id)sender
{
    NSArray	*accountArray;
    AIAccount	*theAccount;
    int d, h, m, t;
    
    accountArray = [[owner accountController] accountArray];
    theAccount = [accountArray objectAtIndex:[accountPopup indexOfSelectedItem]];

    d = [text_SetIdleDays intValue];
    h = [text_SetIdleHours intValue];
    m = [text_SetIdleMinutes intValue];
    t = (d * 86400) + (h * 3600) + (m * 60);
    if(t!=0)
        [(AIAccount<AIAccount_IdleTime> *)theAccount setIdleTime:t manually:TRUE];
    else
        [self unIdle:nil];

    [self close];
}

- (IBAction)unIdle:(id)sender
{
    NSArray	*accountArray;
    AIAccount	*theAccount;

    accountArray = [[owner accountController] accountArray];
    theAccount = [accountArray objectAtIndex:[accountPopup indexOfSelectedItem]];

    [(AIAccount<AIAccount_IdleTime> *)theAccount setIdleTime:0 manually:FALSE];

    [self close];
}

- (IBAction)cancel:(id)sender
{
    [self close];
}

@end
