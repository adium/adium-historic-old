//
//  AIStatusOverlayPreferences.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIStatusOverlayPreferences.h"
#import "AIContactStatusDockOverlaysPlugin.h"

#define STATUS_OVERLAY_PREF_NIB		@"DockStatusOverlaysPrefs"
#define STATUS_OVERLAY_PREF_TITLE	@"Contact Status Overlays"


@interface AIStatusOverlayPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AIStatusOverlayPreferences
//
+ (id)statusOverlayPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Dock_Icon withDelegate:self label:STATUS_OVERLAY_PREF_TITLE]];

    //Configure the view

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:STATUS_OVERLAY_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;

}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_OVERLAYS];

    [checkBox_showStatusOverlays setState:[[preferenceDict objectForKey:KEY_DOCK_SHOW_STATUS] boolValue]];
    [checkBox_showContentOverlays setState:[[preferenceDict objectForKey:KEY_DOCK_SHOW_CONTENT] boolValue]];

    [radioButton_topOfIcon setState:[[preferenceDict objectForKey:KEY_DOCK_OVERLAY_POSITION] boolValue]];
    [radioButton_bottomOfIcon setState:![[preferenceDict objectForKey:KEY_DOCK_OVERLAY_POSITION] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_showStatusOverlays){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DOCK_SHOW_STATUS
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        
    }else if(sender == checkBox_showContentOverlays){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DOCK_SHOW_CONTENT
                                              group:PREF_GROUP_DOCK_OVERLAYS];

    }else if(sender == radioButton_topOfIcon){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                             forKey:KEY_DOCK_OVERLAY_POSITION
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        [radioButton_bottomOfIcon setState:NSOffState];
        
    }else if(sender == radioButton_bottomOfIcon){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                             forKey:KEY_DOCK_OVERLAY_POSITION
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        [radioButton_topOfIcon setState:NSOffState];

    }
}


@end
