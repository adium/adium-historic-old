//
//  AIListThemeWindowController.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListThemeWindowController.h"
#import "AICLPreferences.h"

@implementation AIListThemeWindowController

+ (id)listThemeOnWindow:(NSWindow *)parentWindow withName:(NSString *)inName
{
	AIListThemeWindowController	*listThemeWindow = [[self alloc] initWithWindowNibName:@"ListThemeSheet"
																			  withName:inName];
	
	if(parentWindow){
		[NSApp beginSheet:[listThemeWindow window]
		   modalForWindow:parentWindow
			modalDelegate:listThemeWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[listThemeWindow showWindow:nil];
	}
	
	return(listThemeWindow);
}

- (id)initWithWindowNibName:(NSString *)windowNibName withName:(NSString *)inName
{
    [super initWithWindowNibName:windowNibName];	
	themeName = [inName retain];
	return(self);
}

- (void)dealloc
{
	[themeName release];
    [super dealloc];
}


//Window Methods -------------------------------------------------------------------------------------------------------
#pragma mark Window Methods
- (void)windowDidLoad
{
	[self configureControls];

	[textField_themeName setStringValue:themeName];
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
	NSString	*newName = [textField_themeName stringValue];
	
	//If the user has renamed this theme, delete the old one
	if(![newName isEqualTo:themeName]){
		[AICLPreferences deleteSetWithName:themeName
								 extension:LIST_THEME_EXTENSION
								  inFolder:LIST_THEME_FOLDER];
	}
	
	//Save the theme
	if([AICLPreferences createSetFromPreferenceGroup:PREF_GROUP_LIST_THEME
											withName:[textField_themeName stringValue]
										   extension:LIST_THEME_EXTENSION
											inFolder:LIST_THEME_FOLDER]){

		[[adium preferenceController] setPreference:newName
											 forKey:KEY_LIST_THEME_NAME
											  group:PREF_GROUP_CONTACT_LIST];

		[[adium notificationCenter] postNotificationName:Adium_Xtras_Changed object:LIST_THEME_EXTENSION];
		[self closeWindow:sender];
	}
}


//Window Methods -------------------------------------------------------------------------------------------------------
- (void)configureControls
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];
	
	//Colors
    [colorWell_away setColor:[[preferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[preferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
    [colorWell_signedOff setColor:[[preferenceDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[preferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typing setColor:[[preferenceDict objectForKey:KEY_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[preferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
    [colorWell_online setColor:[[preferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
    [colorWell_idleAndAway setColor:[[preferenceDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_offline setColor:[[preferenceDict objectForKey:KEY_OFFLINE_COLOR] representedColor]];
	
    [colorWell_awayLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor]];
    [colorWell_idleLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor]];
    [colorWell_signedOffLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOnLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typingLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContentLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor]];
    [colorWell_onlineLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor]];
    [colorWell_idleAndAwayLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_offlineLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_OFFLINE_COLOR] representedColor]];
	
    [checkBox_signedOff setState:[[preferenceDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue]];
    [checkBox_signedOn setState:[[preferenceDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue]];
    [checkBox_away setState:[[preferenceDict objectForKey:KEY_AWAY_ENABLED] boolValue]];
    [checkBox_idle setState:[[preferenceDict objectForKey:KEY_IDLE_ENABLED] boolValue]];
    [checkBox_typing setState:[[preferenceDict objectForKey:KEY_TYPING_ENABLED] boolValue]];
    [checkBox_unviewedContent setState:[[preferenceDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue]];
    [checkBox_online setState:[[preferenceDict objectForKey:KEY_ONLINE_ENABLED] boolValue]];
    [checkBox_idleAndAway setState:[[preferenceDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue]];
    [checkBox_offline setState:[[preferenceDict objectForKey:KEY_OFFLINE_ENABLED] boolValue]];
	
	//Groups
	[colorWell_groupText setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR] representedColor]];
	[colorWell_groupTextInverted setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR_INVERTED] representedColor]];
	[colorWell_groupBackground setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND] representedColor]];
	[colorWell_groupBackgroundGradient setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT] representedColor]];
	[colorWell_groupShadow setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR] representedColor]];
		
	//Background Image
	[checkBox_useBackgroundImage setState:[[preferenceDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]];
	NSString *backgroundImagePath = [[preferenceDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH] lastPathComponent];
	if(backgroundImagePath) [textField_backgroundImagePath setStringValue:backgroundImagePath];
	
	//
    [colorWell_background setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_BACKGROUND_COLOR] representedColor]];
    [colorWell_grid setColor:[[preferenceDict objectForKey:KEY_LIST_THEME_GRID_COLOR] representedColor]];	
	[slider_backgroundFade setFloatValue:[[preferenceDict objectForKey:KEY_LIST_THEME_BACKGROUND_FADE] floatValue]];
	[checkBox_drawGrid setState:[[preferenceDict objectForKey:KEY_LIST_THEME_GRID_ENABLED] boolValue]];
	
	[self updateSliderValues];
	[self configureControlDimming];
}

- (void)preferenceChanged:(id)sender
{
#warning LOOK AT THIS GLUE CODE... KILL ME NOW! ... 10.2 USERS BETTER SUCK UP FOR THIS ONE! :D
    if(sender == colorWell_away){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_away setNeedsDisplay:YES];
		
    }else if(sender == colorWell_idle){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_IDLE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idle setNeedsDisplay:YES];
		
    }else if(sender == colorWell_signedOff){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOff setNeedsDisplay:YES];
		
    }else if(sender == colorWell_signedOn){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SIGNED_ON_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOn setNeedsDisplay:YES];
		
    }else if(sender == colorWell_typing){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_TYPING_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_typing setNeedsDisplay:YES];
		
    }else if(sender == colorWell_unviewedContent){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_UNVIEWED_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_unviewedContent setNeedsDisplay:YES];
		
    }else if(sender == colorWell_online){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_ONLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_online setNeedsDisplay:YES];
		
    }else if(sender == colorWell_idleAndAway){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idleAndAway setNeedsDisplay:YES];
		
    }else if(sender == colorWell_offline){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_OFFLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_offline setNeedsDisplay:YES];
		
    }else if(sender == colorWell_signedOffLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOff setNeedsDisplay:YES];
		
    }else if(sender == colorWell_signedOnLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_SIGNED_ON_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_signedOn setNeedsDisplay:YES];
		
    }else if(sender == colorWell_awayLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_away setNeedsDisplay:YES];
		
    }else if(sender == colorWell_idleLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_IDLE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idle setNeedsDisplay:YES];
		
    }else if(sender == colorWell_typingLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_TYPING_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_typing setNeedsDisplay:YES];
		
    }else if(sender == colorWell_unviewedContentLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_UNVIEWED_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_unviewedContent setNeedsDisplay:YES];
		
    }else if(sender == colorWell_onlineLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_ONLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_online setNeedsDisplay:YES];
		
    }else if(sender == colorWell_idleAndAwayLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_idleAndAway setNeedsDisplay:YES];
        
    }else if(sender == colorWell_offlineLabel){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LABEL_OFFLINE_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_offline setNeedsDisplay:YES];
		
        
    }else if(sender == checkBox_signedOff){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SIGNED_OFF_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_signedOn){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SIGNED_ON_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_away){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_AWAY_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_idle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_typing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TYPING_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_unviewedContent){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_UNVIEWED_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_online){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_ONLINE_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_idleAndAway){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_AWAY_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
	}else if(sender == checkBox_offline){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_OFFLINE_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
	}else if(sender == checkBox_useBackgroundImage){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED
											  group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == checkBox_drawGrid){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LIST_THEME_GRID_ENABLED
                                              group:PREF_GROUP_LIST_THEME];
		
    }else if(sender == colorWell_background){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_BACKGROUND_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_background setNeedsDisplay:YES];
		[preview_group setNeedsDisplay:YES];
		
    }else if(sender == colorWell_grid){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GRID_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_grid setNeedsDisplay:YES];

    }else if(sender == slider_backgroundFade){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_LIST_THEME_BACKGROUND_FADE
                                              group:PREF_GROUP_LIST_THEME];
		[self updateSliderValues];
		
    }else if(sender == colorWell_groupText){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_TEXT_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_group setNeedsDisplay:YES];
		
    }else if(sender == colorWell_groupBackground){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_BACKGROUND
                                              group:PREF_GROUP_LIST_THEME];
		[preview_groupInverted setNeedsDisplay:YES];
		
    }else if(sender == colorWell_groupBackgroundGradient){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT
                                              group:PREF_GROUP_LIST_THEME];
		[preview_groupInverted setNeedsDisplay:YES];
		
    }else if(sender == colorWell_groupTextInverted){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_TEXT_COLOR_INVERTED
                                              group:PREF_GROUP_LIST_THEME];
		[preview_groupInverted setNeedsDisplay:YES];
		
    }else if(sender == colorWell_groupShadow){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR
                                              group:PREF_GROUP_LIST_THEME];
		[preview_groupInverted setNeedsDisplay:YES];
		
	}
		
	[self configureControlDimming];
}

//Prompt for an image to use
- (IBAction)selectBackgroundImage:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Background Image"];
	
	if([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton){
		[[adium preferenceController] setPreference:[openPanel filename]
											 forKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH
											  group:PREF_GROUP_LIST_THEME];
		if([openPanel filename]) [textField_backgroundImagePath setStringValue:[openPanel filename]];
	}
}

//
- (void)updateSliderValues
{
	[textField_backgroundFade setStringValue:[NSString stringWithFormat:@"%i%%", (int)([slider_backgroundFade floatValue] * 100.0)]];
}

//Configure control dimming
- (void)configureControlDimming
{
	//Enable/Disable color wells
    [colorWell_signedOff setEnabled:[checkBox_signedOff state]];
    [colorWell_signedOffLabel setEnabled:[checkBox_signedOff state]];	
    [colorWell_signedOn setEnabled:[checkBox_signedOn state]];
    [colorWell_signedOnLabel setEnabled:[checkBox_signedOn state]];
    [colorWell_away setEnabled:[checkBox_away state]];
    [colorWell_awayLabel setEnabled:[checkBox_away state]];
    [colorWell_idle setEnabled:[checkBox_idle state]];
    [colorWell_idleLabel setEnabled:[checkBox_idle state]];
    [colorWell_typing setEnabled:[checkBox_typing state]];
    [colorWell_typingLabel setEnabled:[checkBox_typing state]];
    [colorWell_unviewedContent setEnabled:[checkBox_unviewedContent state]];
    [colorWell_unviewedContentLabel setEnabled:[checkBox_unviewedContent state]];
    [colorWell_online setEnabled:[checkBox_online state]];
    [colorWell_onlineLabel setEnabled:[checkBox_online state]];
    [colorWell_idleAndAway setEnabled:[checkBox_idleAndAway state]];
    [colorWell_idleAndAwayLabel setEnabled:[checkBox_idleAndAway state]];
	[colorWell_offline setEnabled:[checkBox_offline state]];
    [colorWell_offlineLabel setEnabled:[checkBox_offline state]];
	
	//Background image
	[button_setBackgroundImage setEnabled:[checkBox_useBackgroundImage state]];
	[textField_backgroundImagePath setEnabled:[checkBox_useBackgroundImage state]];
}

@end
