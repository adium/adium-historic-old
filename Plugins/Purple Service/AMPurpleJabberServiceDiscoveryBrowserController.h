//
//  AMPurpleJabberServiceDiscoveryBrowserController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import <Adium/AIObject.h>
#include <Libpurple/libpurple.h>

@class AIAccount, AMPurpleJabberNode;

// one instance for every discovery browser window
@interface AMPurpleJabberServiceDiscoveryBrowserController : AIObject
{
	AIAccount *account;
    PurpleConnection *gc;
	
    IBOutlet NSWindow *window;
    IBOutlet NSTextField *servicename;
    IBOutlet NSTextField *nodename;
    IBOutlet NSOutlineView *outlineview;
    
	AMPurpleJabberNode *node;
}

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection *)_gc node:(AMPurpleJabberNode *)_node;

- (IBAction)changeServiceName:(id)sender;
- (IBAction)openService:(id)sender;
- (void)close;

@end
