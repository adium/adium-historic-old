//
//  AICLPreferences.m
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AICLPreferences.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"

#define CL_PREF_NIB		@"AICLPrefView"		//Name of preference nib
#define CL_PREF_TITLE		@"General Appearance"	//

//Handles the interface interaction, and sets preference values
//The outline view plugin is responsible for reading & setting the preferences, as well as observing changes in them

@interface AICLPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)changeFont:(id)sender;
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
- (void)showOpacityPercent;
@end

@implementation AICLPreferences

+ (AICLPreferences *)contactListPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == button_setFont){
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*contactListFont = [[preferenceDict objectForKey:KEY_SCL_FONT] representedFont];

        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_fontName window] setDelegate:self];

        //Setup and show the font panel
        [[textField_fontName window] makeFirstResponder:[textField_fontName window]];
        [fontManager setSelectedFont:contactListFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];
        
    }else if(sender == checkBox_alternatingGrid){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_ALTERNATING_GRID
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == colorWell_group){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == colorWell_group_inverted){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GROUP_COLOR_INVERTED
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == colorWell_grid){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GRID_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];
        
    }else if(sender == colorWell_background){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_BACKGROUND_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];    

    }else if(sender == slider_opacity){
        float	opacity = (100.0 - [sender floatValue]) * 0.01;
        
        [self showOpacityPercent];
        [[owner preferenceController] setPreference:[NSNumber numberWithFloat:opacity]
                                             forKey:KEY_SCL_OPACITY
                                              group:PREF_GROUP_CONTACT_LIST];
    }
    
}



//Private ---------------------------------------------------------------------------
//Called in response to a font panel change
- (void)changeFont:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*contactListFont = [fontManager convertFont:[fontManager selectedFont]];

    //Update the displayed font string & preferences
    [self showFont:contactListFont inField:textField_fontName];
    [[owner preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_SCL_FONT group:PREF_GROUP_CONTACT_LIST];
}

//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;
    
    [super init];

    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:CL_PREF_NIB owner:self];    
    
    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:CL_PREF_TITLE categoryName:PREFERENCE_CATEGORY_CONTACTLIST view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST] retain];
    [self configureView];
    
    return(self);    
}

- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField
{
    if(inFont){
        [inTextField setStringValue:[NSString stringWithFormat:@"%@ %g", [inFont fontName], [inFont pointSize]]];
    }else{
        [inTextField setStringValue:@""];
    }
}

- (void)showOpacityPercent
{
    float	opacity = [slider_opacity floatValue];

    [textField_opacityPercent setStringValue:[NSString stringWithFormat:@"%i",(int)opacity]];
}

//Configures our view for the current preferences
- (void)configureView
{
    //Display
    [self showFont:[[preferenceDict objectForKey:KEY_SCL_FONT] representedFont] inField:textField_fontName];
    [colorWell_group setColor:[[preferenceDict objectForKey:KEY_SCL_GROUP_COLOR] representedColor]];
    [colorWell_group_inverted setColor:[[preferenceDict objectForKey:KEY_SCL_GROUP_COLOR_INVERTED] representedColor]];
    [colorWell_background setColor:[[preferenceDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColor]];

    //Grid
    [checkBox_alternatingGrid setState:[[preferenceDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue]];
    [colorWell_grid setColor:[[preferenceDict objectForKey:KEY_SCL_GRID_COLOR] representedColor]];

    //Alpha
    [slider_opacity setFloatValue:(100 * (1.0 - [[preferenceDict objectForKey:KEY_SCL_OPACITY] floatValue]))];
    [self showOpacityPercent];
}

@end
