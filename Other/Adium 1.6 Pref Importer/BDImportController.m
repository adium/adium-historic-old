/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
