//
//  RAFjoscarAIMAccount.m
//  Adium
//
//  Created by Augie Fackler on 12/18/05.
//

#import "RAFjoscarAIMAccount.h"
#import <AIUtilities/AIStringUtilities.h>
#import <AIUtilities/AIMenuAdditions.h>

#define JOSCAR_CHANGE_PASSWORD_TEXT AILocalizedString(@"Change Password...", "Change Password menu item for AIM accounts")
#define JOSCAR_CONFIRM_ACCOUNT_TEXT AILocalizedString(@"Confirm Account",nil)
#define JOSCAR_DISPLAY_REG_EMAIL_TEXT AILocalizedString(@"Display Currently Registered E-Mail Address",nil)
#define JOSCAR_CHANGE_REG_EMAIL_TEXT AILocalizedString(@"Change Currently Registered E-Mail Address...",nil)

@implementation RAFjoscarAIMAccount

- (NSArray *)accountActionMenuItems
{	
	NSMutableArray			*menuItemArray = [[NSMutableArray alloc] initWithArray:[super accountActionMenuItems]];
	[menuItemArray addObject:[NSMenuItem separatorItem]];
	NSMenuItem *tmpItem = [[NSMenuItem alloc] initWithTitle:JOSCAR_CHANGE_PASSWORD_TEXT
													 target:self
													 action:@selector(handleMenuItem:)
											  keyEquivalent:@""];
	[menuItemArray addObject:[tmpItem autorelease]];
	tmpItem = [[NSMenuItem alloc] initWithTitle:JOSCAR_CONFIRM_ACCOUNT_TEXT
										 target:self
										 action:@selector(handleMenuItem:)
								  keyEquivalent:@""];
	[menuItemArray addObject:[tmpItem autorelease]];
	tmpItem = [[NSMenuItem alloc] initWithTitle:JOSCAR_DISPLAY_REG_EMAIL_TEXT
										 target:self
										 action:@selector(handleMenuItem:)
								  keyEquivalent:@""];
	[menuItemArray addObject:[tmpItem autorelease]];
	tmpItem = [[NSMenuItem alloc] initWithTitle:JOSCAR_CHANGE_REG_EMAIL_TEXT
										 target:self
		
										 action:@selector(handleMenuItem:)
								  keyEquivalent:@""];
	[menuItemArray addObject:[tmpItem autorelease]];
	
	return [menuItemArray autorelease];
}

- (void)handleMenuItem:(id)sender
{
#warning send the user to the correct URL here
#warning there are more cases to handle down here
	if ([[(NSMenuItem *)sender title] isEqualToString:JOSCAR_CHANGE_PASSWORD_TEXT])
		NSLog(@"URL is %@",[joscarAdapter getChangePasswordUrl]);
	else
		[super handleMenuItem:sender];
}

@end
