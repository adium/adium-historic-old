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

#import "ESFileTransferPreferences.h"
#import "ESFileTransferController.h"
#import <Adium/AILocalizationButton.h>
#import <Adium/AILocalizationTextField.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESFileTransferPreferences (PRIVATE)
- (NSMenu *)downloadLocationMenu;
- (void)buildDownloadLocationMenu;
@end

@implementation ESFileTransferPreferences
//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_FileTransfer;
}
- (NSString *)label{
    return @"a";
}
- (NSString *)nibName{
    return @"FileTransferPrefs";
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_autoOpenFiles) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FT_AUTO_OPEN_SAFE
                                              group:PREF_GROUP_FILE_TRANSFER];

	} else if (sender == checkBox_showProgress) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FT_SHOW_PROGRESS_WINDOW
                                              group:PREF_GROUP_FILE_TRANSFER];

	} else if ((sender == checkBox_autoAcceptFiles) ||
			 (sender == checkBox_autoAcceptOnlyFromCLList)) {
		FTAutoAcceptType autoAcceptType;
		
		if ([checkBox_autoAcceptFiles state] == NSOffState) {
			autoAcceptType = AutoAccept_None;
		} else {
			if ([checkBox_autoAcceptOnlyFromCLList state] == NSOnState) {
				autoAcceptType = AutoAccept_FromContactList;
			} else {
				autoAcceptType = AutoAccept_All;
			}
		}
		
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:autoAcceptType]
                                             forKey:KEY_FT_AUTO_ACCEPT
                                              group:PREF_GROUP_FILE_TRANSFER];
		[self configureControlDimming];
		
	} else if (sender == checkBox_autoClearCompleted) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FT_AUTO_CLEAR_COMPLETED
                                              group:PREF_GROUP_FILE_TRANSFER];
	}
}

//Dim controls as needed
- (void)configureControlDimming
{
	[checkBox_autoAcceptOnlyFromCLList setEnabled:([checkBox_autoAcceptFiles state] == NSOnState)];
}

//Configure the preference view
- (void)viewDidLoad
{
	FTAutoAcceptType	autoAcceptType = [[[adium preferenceController] preferenceForKey:KEY_FT_AUTO_ACCEPT
																				   group:PREF_GROUP_FILE_TRANSFER] intValue];
	
	[self buildDownloadLocationMenu];
	
	switch (autoAcceptType) {
		case AutoAccept_None:
			[checkBox_autoAcceptFiles setState:NSOffState];
			[checkBox_autoAcceptOnlyFromCLList setState:NSOffState];			
			break;
			
		case AutoAccept_FromContactList:
			[checkBox_autoAcceptFiles setState:NSOnState];
			[checkBox_autoAcceptOnlyFromCLList setState:NSOnState];
			break;

		case AutoAccept_All:
			[checkBox_autoAcceptFiles setState:NSOnState];
			[checkBox_autoAcceptOnlyFromCLList setState:NSOffState];
			break;
	}
	
	[checkBox_autoOpenFiles setState:[[[adium preferenceController] preferenceForKey:KEY_FT_AUTO_OPEN_SAFE
																			   group:PREF_GROUP_FILE_TRANSFER] boolValue]];
	[checkBox_showProgress setState:[[[adium preferenceController] preferenceForKey:KEY_FT_SHOW_PROGRESS_WINDOW
																			  group:PREF_GROUP_FILE_TRANSFER] boolValue]];
	[checkBox_autoClearCompleted setState:[[[adium preferenceController] preferenceForKey:KEY_FT_AUTO_CLEAR_COMPLETED
																					group:PREF_GROUP_FILE_TRANSFER] boolValue]];

	[self configureControlDimming];
	
	[label_whenReceivingFiles setLocalizedString:AILocalizedString(@"Receiving files:","FT Preferences")];
	[label_defaultReceivingFolder setLocalizedString:AILocalizedString(@"Save files to:","FT Preferences")];
	[label_safeFilesDescription setLocalizedString:AILocalizedString(@"\"Safe\" files include movies, pictures,\nsounds, text documents, and archives.","Description of safe files (files which Adium can open automatically without danger to the user). This description should be on two lines; the lines are separated by \n.")];
	[label_transferProgress setLocalizedString:AILocalizedString(@"Progress:","FT Preferences")];
	
	[checkBox_autoAcceptFiles setLocalizedString:AILocalizedString(@"Automatically accept files...","FT Preferences")];
	[checkBox_autoAcceptOnlyFromCLList setLocalizedString:AILocalizedString(@"only from contacts on my Contact List","FT Preferences")];
	[checkBox_autoOpenFiles setLocalizedString:AILocalizedString(@"Open \"Safe\" files after receiving","FT Preferences")];
	[checkBox_showProgress setLocalizedString:AILocalizedString(@"Show the File Transfers window automatically","FT Preferences")];
	[checkBox_autoClearCompleted setLocalizedString:AILocalizedString(@"Clear completed transfers automatically","FT Preferences")];
}

- (void)buildDownloadLocationMenu
{
	[popUp_downloadLocation setMenu:[self downloadLocationMenu]];
	[popUp_downloadLocation selectItem:[popUp_downloadLocation itemAtIndex:0]];
}

- (NSMenu *)downloadLocationMenu
{
	NSMenu		*menu;
	NSMenuItem	*menuItem;
	NSString	*userPreferredDownloadFolder;

	menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	[menu setAutoenablesItems:NO];
	
	//Create the menu item for the current download folder
	userPreferredDownloadFolder = [[adium preferenceController] userPreferredDownloadFolder];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[userPreferredDownloadFolder lastPathComponent]
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menuItem setImage:[[[NSWorkspace sharedWorkspace] iconForFile:userPreferredDownloadFolder] imageByScalingToSize:NSMakeSize(16,16)]];
	[menu addItem:menuItem];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	//Create the menu item for changing the current download folder
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Other",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(selectOtherDownloadFolder:)
															  keyEquivalent:@""] autorelease];
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menu addItem:menuItem];
	
	return menu;
}

- (void)selectOtherDownloadFolder:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSString	*userPreferredDownloadFolder = [sender representedObject];

	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];

	[openPanel beginSheetForDirectory:userPreferredDownloadFolder
								 file:nil
								types:nil
					   modalForWindow:[[self view] window]
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[[adium preferenceController] setUserPreferredDownloadFolder:[openPanel filename]];
	}

	[self buildDownloadLocationMenu];
}

@end
