#import "BDImportController.h"

@implementation BDImportController

- (id)init
{
	NSMenu *serviceMenu = [[NSMenu alloc] initWithTitle:@"Service"];
	[serviceMenu addItemWithTitle:@"AIM / .Mac" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"MSN" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"ICQ" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Zephyr" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Gadu Gadu" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Yahoo" action:nil keyEquivalent:@""];
	[serviceMenu addItemWithTitle:@"Yahoo Japan" action:nil keyEquivalent:@""];
	[[[table_proteusAccounts tableColumnWithIdentifier:@"ACCOUNT_SERVICE"] dataCell] setMenu:serviceMenu];
	
	proteus = [[[BDProteusImporter alloc] initWithIdentifier:@"Proteus"] retain];
	iChat = [[[BDiChatImporter alloc] initWithIdentifier:@"iChat"] retain];
	fire = [[[BDFireImporter alloc] initWithIdentifier:@"Fire"] retain];
	
	return self;
}

- (void)awakeFromNib
{
	[image_proteusImage setImage:[proteus iconAtSize:48]];
	[panel_importPanel setDelegate:self];
	[panel_importPanel makeKeyAndOrderFront:nil];
}
@end
