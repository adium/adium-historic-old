//
//  AIListLayoutWindowController.m
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListLayoutWindowController.h"


@implementation AIListLayoutWindowController

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow
{
	AIListLayoutWindowController	*listLayoutWindow = [[self alloc] initWithWindowNibName:@"ListLayoutSheet"];

	if(parentWindow){
		[NSApp beginSheet:[listLayoutWindow window]
		   modalForWindow:parentWindow
			modalDelegate:listLayoutWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[listLayoutWindow showWindow:nil];
	}
	
	return(listLayoutWindow);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
	NSLog(@"%@ initWithWindowNibName",self);
	
	return(self);
}

- (void)dealloc
{
	NSLog(@"%@ dealloc",self);
    [super dealloc];
}


//Window Methods -------------------------------------------------------------------------------------------------------
#pragma mark Window Methods
- (void)windowDidLoad
{
	[self configureControls];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	[self autorelease];
    return(YES);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		if([[self window] isSheet]) [NSApp endSheet:[self window]];
        [[self window] close];
    }
}

//Called as the sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel
- (IBAction)cancel:(id)sender
{
    [self closeWindow:sender];
}


//
- (IBAction)okay:(id)sender
{
    [self closeWindow:sender];
}


//Window Methods -------------------------------------------------------------------------------------------------------
- (void)configureControls
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];

	[popUp_contactTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]];
	[popUp_groupTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];
	
	[slider_userIconSize setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];
	[self updateDisplayedUserIconSize];
	
	[checkBox_userIconVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
	[checkBox_extendedStatusVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
	[checkBox_statusIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
	[checkBox_serviceIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];
}

- (void)preferenceChanged:(id)sender
{
	if(sender == popUp_contactTextAlignment){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == popUp_groupTextAlignment){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == popUp_windowStyle){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_WINDOW_STYLE
											  group:PREF_GROUP_LIST_LAYOUT];

	}else if(sender == slider_userIconSize){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_LIST_LAYOUT_USER_ICON_SIZE
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateDisplayedUserIconSize];
		
	}else if(sender == checkBox_userIconVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_ICON
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == checkBox_extendedStatusVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == checkBox_statusIconsVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == checkBox_serviceIconsVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}
	
}

- (void)updateDisplayedUserIconSize
{
	int	iconSize = [slider_userIconSize intValue];
	[textField_userIconSize setStringValue:[NSString stringWithFormat:@"%ix%i",iconSize,iconSize]];
}


























@end
