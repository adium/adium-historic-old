//
//  AIDockBehaviorPreferences.m
//  Adium
//
//  Created by Adam Atlas on Wed Jan 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIDockBehaviorPreferences.h"
#import "AIDockBehaviorPlugin.h"

#define DOCK_BEHAVIOR_PREF_NIB		@"DockBehaviorPreferences"
#define DOCK_BEHAVIOR_PREF_TITLE	@"Dock Behavior"

@interface AIDockBehaviorPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AIDockBehaviorPreferences

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner {
    return [[[self alloc] initWithOwner:inOwner] autorelease];
}

- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:DOCK_BEHAVIOR_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:DOCK_BEHAVIOR_PREF_TITLE categoryName:PREFERENCE_CATEGORY_INTERFACE view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR] retain];
    [self configureView];

    return self;
}

- (void)configureView {
    BOOL enableOverall = [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT] boolValue];
    [checkBox_enableBouncing setState:enableOverall];

    [radioButton_bounceForever setEnabled:enableOverall];
    [radioButton_bounceNTimes setEnabled:enableOverall];
    [textField_thisManyTimes setEnabled:enableOverall];
    [radioButton_bounceConstantly setEnabled:enableOverall];
    [radioButton_bounceEveryNSeconds setEnabled:enableOverall];
    [textField_thisManySeconds setEnabled:enableOverall];
    
    if ([[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] intValue] == 0) {
        [matrix_bounceCount selectCellWithTag:0];
        [textField_thisManyTimes setEnabled:NO];
    } else {
        [matrix_bounceCount selectCellWithTag:1];
        [textField_thisManyTimes setEnabled:YES];
    }
    
    [textField_thisManyTimes setStringValue:[[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] stringValue]];

    if ([[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY] intValue] == 0) {
        [matrix_bounceDelay selectCellWithTag:0];
        [textField_thisManySeconds setEnabled:NO];
    } else {
        [matrix_bounceDelay selectCellWithTag:1];
        [textField_thisManySeconds setEnabled:YES];
    }
    
    [textField_thisManySeconds setStringValue:[[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY] stringValue]];
}

- (IBAction)changePreference:(id)sender {
    if (sender == checkBox_enableBouncing) {
        if ([sender state] == NSOnState) {
            [[owner preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                                 forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT
                                                  group:PREF_GROUP_DOCK_BEHAVIOR];
            [radioButton_bounceForever setEnabled:YES];
            [radioButton_bounceNTimes setEnabled:YES];
            [textField_thisManyTimes setEnabled:YES];
            [radioButton_bounceConstantly setEnabled:YES];
            [radioButton_bounceEveryNSeconds setEnabled:YES];
            [textField_thisManySeconds setEnabled:YES];
        } else {
            [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                                 forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT
                                                  group:PREF_GROUP_DOCK_BEHAVIOR];
            [radioButton_bounceForever setEnabled:NO];
            [radioButton_bounceNTimes setEnabled:NO];
            [textField_thisManyTimes setEnabled:NO];
            [radioButton_bounceConstantly setEnabled:NO];
            [radioButton_bounceEveryNSeconds setEnabled:NO];
            [textField_thisManySeconds setEnabled:NO];
        }
    } else if (sender == matrix_bounceCount && [[matrix_bounceCount selectedCells] objectAtIndex:0] == radioButton_bounceForever) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:0]
                                             forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                              group:PREF_GROUP_DOCK_BEHAVIOR];
        [textField_thisManyTimes setEnabled:NO];
    } else if (sender == matrix_bounceCount && [[matrix_bounceCount selectedCells] objectAtIndex:0] == radioButton_bounceNTimes) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[textField_thisManyTimes intValue]]
                                             forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                              group:PREF_GROUP_DOCK_BEHAVIOR];
        [textField_thisManyTimes setEnabled:YES];
    } else if (sender == textField_thisManyTimes) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[textField_thisManyTimes intValue]]
                                             forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                              group:PREF_GROUP_DOCK_BEHAVIOR];

    } else if (sender == matrix_bounceDelay && [[matrix_bounceDelay selectedCells] objectAtIndex:0] == radioButton_bounceConstantly) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:0]
                                             forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY
                                              group:PREF_GROUP_DOCK_BEHAVIOR];
        [textField_thisManySeconds setEnabled:NO];
    } else if (sender == matrix_bounceDelay && [[matrix_bounceDelay selectedCells] objectAtIndex:0] ==  radioButton_bounceEveryNSeconds) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[textField_thisManySeconds intValue]]
                                             forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY
                                              group:PREF_GROUP_DOCK_BEHAVIOR];
        [textField_thisManySeconds setEnabled:YES];
    } else if (sender == textField_thisManySeconds) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[textField_thisManySeconds intValue]]
                                             forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY
                                              group:PREF_GROUP_DOCK_BEHAVIOR];
    }
}

@end
