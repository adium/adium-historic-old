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

	return(self);
}

- (void)dealloc
{
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
	[popUp_windowStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]];

	[popUp_userIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue]];
	[popUp_statusIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue]];
	[popUp_serviceIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue]];

	[popUp_contactCellStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE] intValue]];
	[popUp_groupCellStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_CELL_STYLE] intValue]];
	
	[slider_userIconSize setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];
	[slider_contactSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
	[slider_groupTopSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] intValue]];
	[slider_groupBottomSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_BOTTOM_SPACING] intValue]];
	[self updateSliderValues];

	[checkBox_userIconVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
	[checkBox_extendedStatusVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
	[checkBox_statusIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
	[checkBox_serviceIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];
	
	[checkBox_windowHasShadow setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_SHADOWED] boolValue]];

	[self configureControlDimming];
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
		[self configureControlDimming];

	}else if(sender == popUp_userIconPosition){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_USER_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == popUp_statusIconPosition){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == popUp_serviceIconPosition){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == popUp_contactCellStyle){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
	}else if(sender == popUp_groupCellStyle){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_GROUP_CELL_STYLE
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == slider_userIconSize){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_LIST_LAYOUT_USER_ICON_SIZE
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
	}else if(sender == slider_contactSpacing){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_LIST_LAYOUT_CONTACT_SPACING
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
	}else if(sender == slider_groupTopSpacing){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
	}else if(sender == slider_groupBottomSpacing){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_LIST_LAYOUT_GROUP_BOTTOM_SPACING
											  group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
	}else if(sender == checkBox_userIconVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_ICON
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];
		
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
		
	}else if(sender == checkBox_windowHasShadow){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_WINDOW_SHADOWED
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}
}

//
- (void)updateSliderValues
{
	int	iconSize = [slider_userIconSize intValue];
	[textField_userIconSize setStringValue:[NSString stringWithFormat:@"%ix%i",iconSize,iconSize]];

	[textField_contactSpacing setStringValue:[NSString stringWithFormat:@"%ipx",[slider_contactSpacing intValue]]];
	[textField_groupTopSpacing setStringValue:[NSString stringWithFormat:@"%ipx",[slider_groupTopSpacing intValue]]];
	[textField_groupBottomSpacing setStringValue:[NSString stringWithFormat:@"%ipx",[slider_groupBottomSpacing intValue]]];
}

//Configure control dimming
- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
	LIST_CELL_STYLE	contactCellStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE] intValue];
	BOOL			windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
	
	//
	[slider_userIconSize setEnabled:[checkBox_userIconVisible state]];
	[textField_userIconSize setEnabled:[checkBox_userIconVisible state]];
	[popUp_userIconPosition setEnabled:[checkBox_userIconVisible state]];
	
	//Disable the style selectors when in mockie mode
	[popUp_groupCellStyle setEnabled:(windowStyle != WINDOW_STYLE_MOCKIE)];
	[popUp_contactCellStyle setEnabled:(windowStyle != WINDOW_STYLE_MOCKIE)];

	//Disable contact spacing when not using bubbles
//	[slider_contactSpacing setEnabled:(contactCellStyle == CELL_STYLE_BUBBLE || contactCellStyle == CELL_STYLE_BUBBLE_FIT)];
//	[textField_contactSpacing setEnabled:(contactCellStyle == CELL_STYLE_BUBBLE || contactCellStyle == CELL_STYLE_BUBBLE_FIT)];

	//Disable group spacing when not using mockie
	[slider_groupTopSpacing setEnabled:(windowStyle == WINDOW_STYLE_MOCKIE)];
	[textField_groupTopSpacing setEnabled:(windowStyle == WINDOW_STYLE_MOCKIE)];
}

@end
