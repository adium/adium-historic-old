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
- (void)configureDimming;
@end

@implementation AIDockBehaviorPreferences

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner 
{
    return [[[self alloc] initWithOwner:inOwner] autorelease];
}
- (IBAction)changePreference:(id)sender 
{

    if(sender == enabledCheckBox)
    {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT
                                        group:PREF_GROUP_DOCK_BEHAVIOR];
    }
    else if(sender == bounceField)
    {	
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                        group:PREF_GROUP_DOCK_BEHAVIOR];    
    }
    else if(sender == delayField)
    {    
        [[owner preferenceController] setPreference:[NSNumber numberWithDouble:[sender doubleValue]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY
                                        group:PREF_GROUP_DOCK_BEHAVIOR];    
    }
    
    [self configureDimming];
} 

//-------Private----------------------------------

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

//configure our view
- (void)configureView 
{
    [enabledCheckBox setState:
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT] boolValue]];
    [bounceField setIntValue: 
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] intValue]];
    [delayField setDoubleValue:
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY] doubleValue]];
    
    [self configureDimming];
}

//enable and disable the boxes
- (void)configureDimming
{	
    [bounceField setEnabled:[enabledCheckBox state]];
    [delayField setEnabled:[enabledCheckBox state]];
}   
@end
