//
//  AIListLayoutWindowController.m
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListLayoutWindowController.h"
#import "AICLPreferences.h"
#import "AISCLViewPlugin.h"

@interface AIListLayoutWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withName:(NSString *)inName;
- (void)configureControls;
- (void)configureControlDimming;
- (void)updateSliderValues;
@end

@implementation AIListLayoutWindowController

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow withName:(NSString *)inName
{
	AIListLayoutWindowController	*listLayoutWindow = [[self alloc] initWithWindowNibName:@"ListLayoutSheet"
																				   withName:inName];

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

- (id)initWithWindowNibName:(NSString *)windowNibName withName:(NSString *)inName
{
    [super initWithWindowNibName:windowNibName];
	layoutName = [inName retain];
	return(self);
}

- (void)dealloc
{
	[layoutName release];
    [super dealloc];
}


//Window Methods -------------------------------------------------------------------------------------------------------
#pragma mark Window Methods
- (void)windowDidLoad
{
	[self configureControls];

	[fontField_contact setShowPointSize:YES];
	[fontField_contact setShowFontFace:YES];
	[fontField_status setShowPointSize:YES];
	[fontField_status setShowFontFace:YES];
	[fontField_group setShowPointSize:YES];
	[fontField_group setShowFontFace:YES];
	
	[textField_layoutName setStringValue:(layoutName ? layoutName : @"")];
	
	[popUp_contactCellStyle setAutoenablesItems:NO];
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
	//Revert
	[[adium preferenceController] setPreference:layoutName
										 forKey:KEY_LIST_LAYOUT_NAME
										  group:PREF_GROUP_CONTACT_LIST];
	[self closeWindow:sender];
}

//
- (IBAction)okay:(id)sender
{
	NSString	*newName = [textField_layoutName stringValue];
	
	//If the user has renamed this layout, delete the old one
	if(![newName isEqualTo:layoutName]){
		[AISCLViewPlugin deleteSetWithName:layoutName
								 extension:LIST_LAYOUT_EXTENSION
								  inFolder:LIST_LAYOUT_FOLDER];
	}
	
	//Save the layout
	if([AISCLViewPlugin createSetFromPreferenceGroup:PREF_GROUP_LIST_LAYOUT
											withName:[textField_layoutName stringValue]
										   extension:LIST_LAYOUT_EXTENSION
											inFolder:LIST_LAYOUT_FOLDER]){
		[[adium notificationCenter] postNotificationName:Adium_Xtras_Changed object:LIST_LAYOUT_EXTENSION];

		[[adium preferenceController] setPreference:newName
											 forKey:KEY_LIST_LAYOUT_NAME
											  group:PREF_GROUP_CONTACT_LIST];
		
		[self closeWindow:sender];
	}
}


//Window Methods -------------------------------------------------------------------------------------------------------
- (void)configureControls
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];

	[popUp_contactTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]];
	[popUp_groupTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];
	[popUp_windowStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]];

	[popUp_extendedStatusPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] intValue]];
	[popUp_userIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue]];
	[popUp_statusIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue]];
	[popUp_serviceIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue]];

	[popUp_contactCellStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE] intValue]];
	[popUp_groupCellStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_CELL_STYLE] intValue]];
	
	[slider_userIconSize setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];
	[slider_contactSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
	[slider_groupTopSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] intValue]];
	[slider_groupBottomSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_BOTTOM_SPACING] intValue]];
	[slider_windowTransparency setFloatValue:([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue] * 100.0)];
	[slider_contactLeftIndent setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
	[slider_contactRightIndent setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
	[self updateSliderValues];
	
	[checkBox_userIconVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
	[checkBox_extendedStatusVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
	[checkBox_statusIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
	[checkBox_serviceIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];	
	[checkBox_windowHasShadow setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_SHADOWED] boolValue]];
	[checkBox_verticalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue]];
	[checkBox_horizontalAutosizing setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue]];
	
	[fontField_contact setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_FONT] representedFont]];
	[fontField_status setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_FONT] representedFont]];
	[fontField_group setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_FONT] representedFont]];

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
		
	}else if(sender == popUp_extendedStatusPosition){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION
											  group:PREF_GROUP_LIST_LAYOUT];
		
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
		
    }else if(sender == checkBox_verticalAutosizing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE
                                              group:PREF_GROUP_LIST_LAYOUT];
		
    }else if(sender == checkBox_horizontalAutosizing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE
                                              group:PREF_GROUP_LIST_LAYOUT];
			
    }else if(sender == slider_windowTransparency){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:([sender floatValue] / 100.0)]
                                             forKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];

    }else if(sender == slider_contactLeftIndent){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
		
    }else if(sender == slider_contactRightIndent){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT
                                              group:PREF_GROUP_LIST_LAYOUT];
		[self updateSliderValues];
	}
}

- (BOOL)fontPreviewField:(JVFontPreviewField *)field shouldChangeToFont:(NSFont *)font
{
	return(YES);
}

- (void)fontPreviewField:(JVFontPreviewField *)field didChangeToFont:(NSFont *)font
{
	if(field == fontField_contact){
        [[adium preferenceController] setPreference:[font stringRepresentation]
                                             forKey:KEY_LIST_LAYOUT_CONTACT_FONT
                                              group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(field == fontField_status){
        [[adium preferenceController] setPreference:[font stringRepresentation]
                                             forKey:KEY_LIST_LAYOUT_STATUS_FONT
                                              group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(field == fontField_group){
		NSLog(@"%@",[font stringRepresentation]);
        [[adium preferenceController] setPreference:[font stringRepresentation]
                                             forKey:KEY_LIST_LAYOUT_GROUP_FONT
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
	[textField_windowTransparency setStringValue:[NSString stringWithFormat:@"%i%%", (int)[slider_windowTransparency floatValue]]];
	[textField_contactLeftIndent setStringValue:[NSString stringWithFormat:@"%ipx",[slider_contactLeftIndent intValue]]];
	[textField_contactRightIndent setStringValue:[NSString stringWithFormat:@"%ipx",[slider_contactRightIndent intValue]]];
}

//Configure control dimming
- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
	BOOL			windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
	
	//
	[slider_userIconSize setEnabled:[checkBox_userIconVisible state]];
	[textField_userIconSize setEnabled:[checkBox_userIconVisible state]];
	[popUp_userIconPosition setEnabled:[checkBox_userIconVisible state]];
	
	//Disable the style selectors when in mockie mode
	[popUp_groupCellStyle setEnabled:(windowStyle != WINDOW_STYLE_MOCKIE)];

	//Disable group spacing when not using mockie
	[slider_groupTopSpacing setEnabled:(windowStyle == WINDOW_STYLE_MOCKIE)];
	[textField_groupTopSpacing setEnabled:(windowStyle == WINDOW_STYLE_MOCKIE)];
	
	//Contact style
	BOOL	enableNormal = (windowStyle != WINDOW_STYLE_PILLOWS);
	BOOL	enableBubble = (windowStyle != WINDOW_STYLE_MOCKIE);
	[[[popUp_contactCellStyle menu] itemWithTag:CELL_STYLE_STANDARD] setEnabled:enableNormal];
	[[[popUp_contactCellStyle menu] itemWithTag:CELL_STYLE_BRICK] setEnabled:enableNormal];
	[[[popUp_contactCellStyle menu] itemWithTag:CELL_STYLE_BUBBLE] setEnabled:enableBubble];
	[[[popUp_contactCellStyle menu] itemWithTag:CELL_STYLE_BUBBLE_FIT] setEnabled:enableBubble];
}


@end
