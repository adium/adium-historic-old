//
//  AIListLayoutWindowController.m
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//

#import "AIListLayoutWindowController.h"
#import "AICLPreferences.h"
#import "AISCLViewPlugin.h"

#define	MAX_ALIGNMENT_CHOICES	10

@interface AIListLayoutWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withName:(NSString *)inName;
- (void)configureControls;
- (void)configureControlDimming;
- (void)updateSliderValues;
- (void)updateStatusAndServiceIconMenusFromPrefDict:(NSDictionary *)prefDict;
- (void)updateUserIconMenuFromPrefDict:(NSDictionary *)prefDict;
- (NSMenu *)alignmentMenuWithChoices:(int [])alignmentChoices;
- (NSMenu *)positionMenuWithChoices:(int [])positionChoices;
- (NSMenu *)extendedStatusStyleMenu;
- (NSMenu *)extendedStatusPositionMenu;
- (NSMenu *)windowStyleMenu;
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
	int				textAlignmentChoices[4];
	
	textAlignmentChoices[0] = NSLeftTextAlignment;
	textAlignmentChoices[1] = NSCenterTextAlignment;
	textAlignmentChoices[2] = NSRightTextAlignment;
	textAlignmentChoices[3] = -1;

	[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
	
	[self updateUserIconMenuFromPrefDict:prefDict];
	
	//Context text alignment
	[popUp_contactTextAlignment setMenu:[self alignmentMenuWithChoices:textAlignmentChoices]];
	[popUp_contactTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]];
	
	//Group text alignment
	[popUp_groupTextAlignment setMenu:[self alignmentMenuWithChoices:textAlignmentChoices]];
	[popUp_groupTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];

	//Extended Status position
	[popUp_extendedStatusPosition setMenu:[self extendedStatusPositionMenu]];
	[popUp_extendedStatusPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] intValue]];
	
	//Window style
	[popUp_windowStyle setMenu:[self windowStyleMenu]];
	[popUp_windowStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]];

	[popUp_extendedStatusStyle setMenu:[self extendedStatusStyleMenu]];
	[popUp_extendedStatusStyle compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] intValue]];
	
	[slider_userIconSize setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];
	[slider_contactSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
	[slider_groupTopSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] intValue]];
	[slider_groupBottomSpacing setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_BOTTOM_SPACING] intValue]];
	[slider_windowTransparency setFloatValue:([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue] * 100.0)];
	[slider_contactLeftIndent setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
	[slider_contactRightIndent setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
	[slider_horizontalWidth setIntValue:[[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue]];
	[self updateSliderValues];
	
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
		
		NSDictionary	*prefDict;
		prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];

		[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
		[self updateUserIconMenuFromPrefDict:prefDict];
		
		[self configureControlDimming];

	}else if(sender == popUp_groupTextAlignment){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
		
	}else if(sender == popUp_windowStyle){
		NSDictionary	*prefDict;
		
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_WINDOW_STYLE
											  group:PREF_GROUP_LIST_LAYOUT];

		prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];

		[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
		[self updateUserIconMenuFromPrefDict:prefDict];

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
		
	}else if (sender == popUp_extendedStatusStyle){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE
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
		NSDictionary	*prefDict;
		
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_ICON
											  group:PREF_GROUP_LIST_LAYOUT];
		
		prefDict  = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		//Update the status and service icon menus to show/hide the badge options
		[self updateStatusAndServiceIconMenusFromPrefDict:prefDict];
		[self configureControlDimming];
		
	}else if(sender == checkBox_extendedStatusVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];

	}else if(sender == checkBox_statusIconsVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];

	}else if(sender == checkBox_serviceIconsVisible){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS
											  group:PREF_GROUP_LIST_LAYOUT];
		[self configureControlDimming];

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
		[self configureControlDimming];
			
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
		
	}else if(sender == slider_horizontalWidth){
		int newValue = [sender intValue];
		int oldValue = [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH
																group:PREF_GROUP_LIST_LAYOUT] intValue];
		if (newValue != oldValue){ 
			[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
												 forKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH
												  group:PREF_GROUP_LIST_LAYOUT];
			[self updateSliderValues];
		}
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
	[textField_horizontalWidthIndicator setStringValue:[NSString stringWithFormat:@"%ipx",[slider_horizontalWidth intValue]]];
}

//Configure control dimming
- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
	int				windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
	BOOL			horizontalAutosize = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
	
	//Bubble to fit limitations
	BOOL nonFitted = (windowStyle != WINDOW_STYLE_PILLOWS_FITTED);
	if (nonFitted){
		//For the non-fitted styles, enable and set the proper state
		[checkBox_extendedStatusVisible setEnabled:YES];
		[checkBox_extendedStatusVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
	}else{
		//For the fitted style, disable and set to NO the extendedStatus
		[checkBox_extendedStatusVisible setEnabled:NO];
		[checkBox_extendedStatusVisible setState:NO];
	}
	
	if (nonFitted || ([[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue] != NSCenterTextAlignment)){
		//For non-fitted or non-centered fitted, enable and set the appropriate value
		[checkBox_userIconVisible setEnabled:YES];
		[checkBox_userIconVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];

		[checkBox_statusIconsVisible setEnabled:YES];
		[checkBox_statusIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];

		[checkBox_serviceIconsVisible setEnabled:YES];
		[checkBox_serviceIconsVisible setState:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];	

	}else{
		//For fitted and centered, disable and set to NO
		[checkBox_userIconVisible setEnabled:NO];
		[checkBox_userIconVisible setState:NO];
		
		[checkBox_statusIconsVisible setEnabled:NO];
		[checkBox_statusIconsVisible setState:NO];
		
		[checkBox_serviceIconsVisible setEnabled:NO];
		[checkBox_serviceIconsVisible setState:NO];
	}



	
	//User icon controls
	[slider_userIconSize setEnabled:([checkBox_userIconVisible state] && [checkBox_userIconVisible isEnabled])];
	[textField_userIconSize setEnabled:([checkBox_userIconVisible state] && [checkBox_userIconVisible isEnabled])];
	[popUp_userIconPosition setEnabled:([checkBox_userIconVisible state] && [checkBox_userIconVisible isEnabled])];
	
	//Other controls
	BOOL extendedStatusEnabled = ([checkBox_extendedStatusVisible state] && [checkBox_extendedStatusVisible isEnabled]);
	

	[popUp_extendedStatusStyle setEnabled:extendedStatusEnabled];
	[popUp_extendedStatusPosition setEnabled:extendedStatusEnabled];
	[popUp_statusIconPosition setEnabled:([checkBox_statusIconsVisible state] && 
										  [checkBox_statusIconsVisible isEnabled] &&
										  ([popUp_statusIconPosition numberOfItems] > 0))];
	[popUp_serviceIconPosition setEnabled:([checkBox_serviceIconsVisible state] &&
										   [checkBox_serviceIconsVisible isEnabled] &&
										   ([popUp_serviceIconPosition numberOfItems] > 0))];
	[popUp_userIconPosition setEnabled:([checkBox_userIconVisible state] &&
										[checkBox_userIconVisible isEnabled] &&
										([popUp_userIconPosition numberOfItems] > 0))];

	//Disable group spacing when not using mockie
	[slider_groupTopSpacing setEnabled:(windowStyle == WINDOW_STYLE_MOCKIE)];
	[textField_groupTopSpacing setEnabled:(windowStyle == WINDOW_STYLE_MOCKIE)];
	
	//Contact style
	if(windowStyle == WINDOW_STYLE_STANDARD){
		//In standard mode, disable the horizontal autosizing slider if horiztonal autosizing is off
		[textField_horizontalWidthText setStringValue:AILocalizedString(@"Maximum width:",nil)];
		[slider_horizontalWidth setEnabled:horizontalAutosize];

	}else{
		//In all the borderless transparent modes, the horizontal autosizing slider becomes the
		//horizontal sizing slider when autosizing is off
		if (horizontalAutosize){
			[textField_horizontalWidthText setStringValue:AILocalizedString(@"Maximum width:",nil)];
		}else{
			[textField_horizontalWidthText setStringValue:AILocalizedString(@"Width:",nil)];			
		}
		[slider_horizontalWidth setEnabled:YES];
	}
}

- (void)updateStatusAndServiceIconMenusFromPrefDict:(NSDictionary *)prefDict
{
	int				statusAndServicePositionChoices[7];
	BOOL			showUserIcon = [[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue];
	int				indexForFinishingChoices = 0;
	
	if ([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue] != WINDOW_STYLE_PILLOWS_FITTED){
		statusAndServicePositionChoices[0] = LIST_POSITION_FAR_LEFT;
		statusAndServicePositionChoices[1] = LIST_POSITION_LEFT;
		statusAndServicePositionChoices[2] = LIST_POSITION_RIGHT;
		statusAndServicePositionChoices[3] = LIST_POSITION_FAR_RIGHT;
		
		indexForFinishingChoices = 4;
		
	}else{
		//For fitted pillows, only show the options which correspond to the text alignment
		switch([[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]){
			case NSLeftTextAlignment:
				statusAndServicePositionChoices[0] = LIST_POSITION_FAR_LEFT;
				statusAndServicePositionChoices[1] = LIST_POSITION_LEFT;
				indexForFinishingChoices = 2;
				break;
				
			case NSRightTextAlignment:
				statusAndServicePositionChoices[0] = LIST_POSITION_RIGHT;
				statusAndServicePositionChoices[1] = LIST_POSITION_FAR_RIGHT;
				indexForFinishingChoices = 2;
				
				break;
			case NSCenterTextAlignment:
				
				break;
		}	
	}
	
	//Only show the badge choices if we are showing the user icon
	if (showUserIcon && (indexForFinishingChoices != 0)){
		statusAndServicePositionChoices[indexForFinishingChoices] = LIST_POSITION_BADGE_LEFT;
		statusAndServicePositionChoices[indexForFinishingChoices + 1] = LIST_POSITION_BADGE_RIGHT;
		statusAndServicePositionChoices[indexForFinishingChoices + 2] = -1;

	}else{
		statusAndServicePositionChoices[indexForFinishingChoices] = -1;

	}

	[popUp_statusIconPosition setMenu:[self positionMenuWithChoices:statusAndServicePositionChoices]];
	[popUp_statusIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue]];
	
	[popUp_serviceIconPosition setMenu:[self positionMenuWithChoices:statusAndServicePositionChoices]];
	[popUp_serviceIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue]];	
}

- (void)updateUserIconMenuFromPrefDict:(NSDictionary *)prefDict
{
	int				userIconPositionChoices[3];
	
	if ([[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue] != WINDOW_STYLE_PILLOWS_FITTED){
		userIconPositionChoices[0] = LIST_POSITION_LEFT;
		userIconPositionChoices[1] = LIST_POSITION_RIGHT;
		userIconPositionChoices[2] = -1;
	}else{
		//For fitted pillows, only show the options which correspond to the text alignment
		switch([[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]){
			case NSLeftTextAlignment:
				userIconPositionChoices[0] = LIST_POSITION_LEFT;
				userIconPositionChoices[1] = -1;
				break;
				
			case NSRightTextAlignment:		
				userIconPositionChoices[0] = LIST_POSITION_RIGHT;
				userIconPositionChoices[1] = -1;
				break;
			case NSCenterTextAlignment:
				userIconPositionChoices[0] = -1;				
				break;
		}	
	}

	
	//User icon position
	[popUp_userIconPosition setMenu:[self positionMenuWithChoices:userIconPositionChoices]];
	[popUp_userIconPosition compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue]];
}

#pragma mark Menu generation

- (NSMenu *)alignmentMenuWithChoices:(int [])alignmentChoices
{
    NSMenu		*alignmentMenu = [[[NSMenu alloc] init] autorelease];
	NSMenuItem	*menuItem;
    
	unsigned	i = 0;
	
	while (alignmentChoices[i] != -1){
		NSString	*menuTitle = nil;
		
		switch(alignmentChoices[i]) {
			case NSLeftTextAlignment:	menuTitle = AILocalizedString(@"Left",nil);
				break;
			case NSCenterTextAlignment:	menuTitle = AILocalizedString(@"Center",nil);
				break;
			case NSRightTextAlignment:	menuTitle = AILocalizedString(@"Right",nil);
				break;
		}
		menuItem = [[[NSMenuItem alloc] initWithTitle:menuTitle
											   target:nil
											   action:nil
										keyEquivalent:@""] autorelease];
		[menuItem setTag:alignmentChoices[i]];
		[alignmentMenu addItem:menuItem];
		
		i++;
	}
	
	return(alignmentMenu);
	
}

- (NSMenu *)positionMenuWithChoices:(int [])positionChoices
{
    NSMenu		*positionMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem	*menuItem;
    
	unsigned	i = 0;
	
	while (positionChoices[i] != -1){
		NSString	*menuTitle = nil;
		
		switch(positionChoices[i]) {
			case LIST_POSITION_LEFT:
				menuTitle = AILocalizedString(@"Left",nil);
				break;
			case LIST_POSITION_RIGHT:
				menuTitle = AILocalizedString(@"Right",nil);
				break;
			case LIST_POSITION_FAR_LEFT: menuTitle = AILocalizedString(@"Far Left",nil);
				break;
			case LIST_POSITION_FAR_RIGHT: menuTitle = AILocalizedString(@"Far Right",nil);
				break;
			case LIST_POSITION_BADGE_LEFT: menuTitle = AILocalizedString(@"Badge (Lower Left)",nil);
				break;
			case LIST_POSITION_BADGE_RIGHT: menuTitle = AILocalizedString(@"Badge (Lower Right)",nil);
				break;
		}
		menuItem = [[[NSMenuItem alloc] initWithTitle:menuTitle
											   target:nil
											   action:nil
										keyEquivalent:@""] autorelease];
		[menuItem setTag:positionChoices[i]];
		[positionMenu addItem:menuItem];
		
		i++;
	}

	return(positionMenu);
}

- (NSMenu *)extendedStatusPositionMenu
{
	NSMenu		*extendedStatusPositionMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem	*menuItem;
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Below Name",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:EXTENDED_STATUS_POSITION_BELOW_NAME];
	[extendedStatusPositionMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Beside Name",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:EXTENDED_STATUS_POSITION_BESIDE_NAME];
	[extendedStatusPositionMenu addItem:menuItem];
	
	return(extendedStatusPositionMenu);
}

- (NSMenu *)extendedStatusStyleMenu
{
    NSMenu		*extendedStatusStyleMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem	*menuItem;

	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Status",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:STATUS_ONLY];
	[extendedStatusStyleMenu addItem:menuItem];

	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Idle Time",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:IDLE_ONLY];
	[extendedStatusStyleMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"(Idle) Status",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:IDLE_AND_STATUS];
	[extendedStatusStyleMenu addItem:menuItem];
	
	return(extendedStatusStyleMenu);
}

- (NSMenu *)windowStyleMenu
{
	NSMenu		*windowStyleMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem	*menuItem;
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Regular Window",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:WINDOW_STYLE_STANDARD];
	[windowStyleMenu addItem:menuItem];

	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Borderless Window",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:WINDOW_STYLE_BORDERLESS];
	[windowStyleMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Group Bubbles",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:WINDOW_STYLE_MOCKIE];
	[windowStyleMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Contact Bubbles",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:WINDOW_STYLE_PILLOWS];
	[windowStyleMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Contact Bubbles (To Fit)",nil)
										   target:nil
										   action:nil
									keyEquivalent:@""] autorelease];
	[menuItem setTag:WINDOW_STYLE_PILLOWS_FITTED];
	[windowStyleMenu addItem:menuItem];
	
	return(windowStyleMenu);
}
@end
