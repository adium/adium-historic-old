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
@end

@implementation AIStatusOverlayPreferences

+ (id)statusOverlayPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:STATUS_OVERLAY_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:STATUS_OVERLAY_PREF_TITLE categoryName:PREFERENCE_CATEGORY_DOCK view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_OVERLAYS] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
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
