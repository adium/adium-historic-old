//
//  ESFileTransferPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 11/27/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESFileTransferPreferences.h"

@interface ESFileTransferPreferences (PRIVATE)
- (NSMenu *)downloadLocationMenu;
- (void)buildDownloadLocationMenu;
@end

@implementation ESFileTransferPreferences
//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_FileTransfer);
}
- (NSString *)label{
    return(@"a");
}
- (NSString *)nibName{
    return(@"FileTransferPrefs");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_autoOpenFiles){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FT_AUTO_OPEN_SAFE
                                              group:PREF_GROUP_FILE_TRANSFER];

	}else if(sender == checkBox_showProgress){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FT_SHOW_PROGRESS_WINDOW
                                              group:PREF_GROUP_FILE_TRANSFER];

	}else if((sender == checkBox_autoAcceptFiles) ||
			 (sender == checkBox_autoAcceptOnlyFromCLList)){
		FTAutoAcceptType autoAcceptType;
		
		if([checkBox_autoAcceptFiles state] == NSOffState){
			autoAcceptType = AutoAccept_None;
		}else{
			if([checkBox_autoAcceptOnlyFromCLList state] == NSOnState){
				autoAcceptType = AutoAccept_FromContactList;
			}else{
				autoAcceptType = AutoAccept_All;
			}
		}
		
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:autoAcceptType]
                                             forKey:KEY_FT_AUTO_ACCEPT
                                              group:PREF_GROUP_FILE_TRANSFER];
		[self configureControlDimming];
		
	}else if(sender == checkBox_autoClearCompleted){
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
    NSDictionary		*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_FILE_TRANSFER];
	FTAutoAcceptType	autoAcceptType = [[prefDict objectForKey:KEY_FT_AUTO_ACCEPT] intValue];
	
	[self buildDownloadLocationMenu];
	
	switch(autoAcceptType){
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
	
	[checkBox_autoOpenFiles setState:[[prefDict objectForKey:KEY_FT_AUTO_OPEN_SAFE] boolValue]];
	[checkBox_showProgress setState:[[prefDict objectForKey:KEY_FT_SHOW_PROGRESS_WINDOW] boolValue]];
	[checkBox_autoClearCompleted setState:[[prefDict objectForKey:KEY_FT_AUTO_CLEAR_COMPLETED] boolValue]];

	[self configureControlDimming];
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
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Other...",nil)
																	 target:self
																	 action:@selector(selectOtherDownloadFolder:)
															  keyEquivalent:@""] autorelease];
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menu addItem:menuItem];
	
	return(menu);
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
	if(returnCode == NSOKButton){
		[[adium preferenceController] setUserPreferredDownloadFolder:[openPanel filename]];
	}

	[self buildDownloadLocationMenu];
}

@end
