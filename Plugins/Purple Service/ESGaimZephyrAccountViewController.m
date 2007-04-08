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

#import "ESGaimZephyrAccountViewController.h"
#import "ESGaimZephyrAccount.h"
#import <Adium/AIAccount.h>

@implementation ESGaimZephyrAccountViewController

- (NSString *)nibName{
    return @"ESGaimZephyrAccountView";
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[checkBox_exportAnyone setState:[[account preferenceForKey:KEY_ZEPHYR_EXPORT_ANYONE group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_exportSubs setState:[[account preferenceForKey:KEY_ZEPHYR_EXPORT_SUBS group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	[textField_exposure setStringValue:[account preferenceForKey:KEY_ZEPHYR_EXPOSURE group:GROUP_ACCOUNT_STATUS]];
	[textField_encoding setStringValue:[account preferenceForKey:KEY_ZEPHYR_ENCODING group:GROUP_ACCOUNT_STATUS]];
}

- (IBAction)changedPreference:(id)sender
{	
	if (sender == checkBox_exportAnyone) {
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_EXPORT_ANYONE
						 group:GROUP_ACCOUNT_STATUS];
		
	} else if (sender == checkBox_exportSubs) {
		[account setPreference:[NSNumber numberWithBool:[sender state]]
						forKey:KEY_ZEPHYR_EXPORT_SUBS
						 group:GROUP_ACCOUNT_STATUS];
	} else {
		[super changedPreference:sender];
	}
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *sender = [notification object];
	if (sender == textField_exposure) {
		NSString *exposure = [sender stringValue];
		[account setPreference:([exposure length] ? exposure : nil)
						forKey:KEY_ZEPHYR_EXPOSURE
						 group:GROUP_ACCOUNT_STATUS];
		
	} else if (sender == textField_encoding) {
		NSString *encoding = [sender stringValue];

		[account setPreference:([encoding length] ? encoding : nil)
						forKey:KEY_ZEPHYR_ENCODING
						 group:GROUP_ACCOUNT_STATUS];
	} else {
		[super controlTextDidChange:notification];
	}		
}

@end
