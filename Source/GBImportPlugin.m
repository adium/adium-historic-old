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

#import "GBImportPlugin.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import "GBFireImporter.h"
#import "GBFireLogImporter.h"

@implementation GBImportPlugin

- (void)installPlugin
{
	importMenuRoot = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Import", nil)
												target:nil
												action:nil
										 keyEquivalent:@""];
	[[adium menuController] addMenuItem:importMenuRoot toLocation:LOC_File_Additions];
	
	NSMenuItem *importFire = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Fire Accounts and Logs", nil)
														target:self
														action:@selector(importFire:)
												 keyEquivalent:@""];
	NSMenuItem *importFireLogs = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Fire Logs", nil)
															target:self
															action:@selector(importFireLogs:)
													 keyEquivalent:@""];
	NSMenu *subMenu = [[NSMenu alloc] init];
	[importMenuRoot setSubmenu:subMenu];
	[subMenu release];
	
	[subMenu addItem:importFire];
	[subMenu addItem:importFireLogs];
}

- (void)uninstallPlugin
{
	[importMenuRoot release];
}

- (void)importFire:(id)sender
{
	[GBFireImporter importFireConfiguration];
}

- (void)importFireLogs:(id)sender
{
	[GBFireLogImporter importLogs];
}

@end
