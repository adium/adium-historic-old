//
//  ESBlockingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//

#import "ESBlockingPlugin.h"

#define BLOCK_CONTACT @"Block Contact"

@interface ESBlockingPlugin(PRIVATE)
- (void)blockContact:(AIListContact *)contact forAccount:(AIAccount *)account;
@end

@implementation ESBlockingPlugin

- (void)installPlugin
{
	//Install the Block menu item
	blockContactMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
														 target:self
														 action:@selector(blockContact:)
												  keyEquivalent:@""];
	//[[adium menuController] addMenuItem:blockContactMenuItem toLocation:LOC_Contact_NegativeAction];
	
	
    //Add our get info contextual menu item
    blockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT target:self action:@selector(blockContextContact:) keyEquivalent:@""];
    //[[adium menuController] addContextualMenuItem:blockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];
	
}

- (IBAction)blockContact:(id)sender
{
    AIListObject *object = [[adium contactController] selectedListObject];
    
    //We don't want to block groups
    if([object isKindOfClass:[AIListContact class]]){
        AIListContact *contact = (AIListContact *)object;
        [self blockContact:contact forAccount:[[adium accountController] accountWithObjectID:[contact accountID]]];
    }
}

- (IBAction)blockContextContact:(id)sender
{
    AIListContact *contact = [[adium menuController] contactualMenuContact];
    [self blockContact:contact forAccount:[[adium accountController] accountWithObjectID:[contact accountID]]];
}

- (void)blockContact:(AIListContact *)contact forAccount:(AIAccount *)account
{
    if([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
        if([(AIAccount <AIAccount_Privacy> *)account addListObject:contact toPrivacyList:PRIVACY_DENY]){
        }else{
                NSLog(@"Not blocked");
        }
    }else{
        NSLog(@"No privacy protcol");
        NSLog(@"%@",[account class]);
        
    }
    
}

@end
