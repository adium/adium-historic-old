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
    [self configureDimming]; // this has to go first.
    
    if(sender == enableBouncingCheckBox)
    {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT
                                        group:PREF_GROUP_DOCK_BEHAVIOR];
    }
    else if(sender == bounceField)
    {	
        
    if([sender intValue] >= 0)
        {
            [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                            forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                            group:PREF_GROUP_DOCK_BEHAVIOR];
        }
        else
        {
            NSBeep();
            [sender setSelected: YES];
        }
    }
    else if(sender == delayField)
    {    
        if([sender doubleValue] >= 0)
        {
            [[owner preferenceController] 
                setPreference:[NSNumber numberWithDouble:[sender doubleValue]]
                            forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY
                            group:PREF_GROUP_DOCK_BEHAVIOR];
        }
        else
        {
            NSBeep();
            [sender setSelected: YES];
        }
    }
    else if(sender == bounceMatrix)
    {
        if([[sender selectedCell] tag] == 0) //forever mode
        {
            [[owner preferenceController] setPreference:[NSNumber numberWithInt:-1]
                                            forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                            group:PREF_GROUP_DOCK_BEHAVIOR];
        }
        else
        {
            [[sender window] makeFirstResponder:bounceField];
        }
    }
    
    else if(sender == enableAnimationCheckBox)
    {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_ANIMATE
                                        group:PREF_GROUP_DOCK_BEHAVIOR];
    }
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
    [enableBouncingCheckBox setState:
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT] boolValue]];
    
    if([[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] intValue] == -1)
    {
        [bounceMatrix selectCellWithTag:0];
    }
    else
    {
        [bounceMatrix selectCellWithTag:1];
        [bounceField setIntValue: 
            [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] intValue]];
    }
    
    [delayField setDoubleValue:
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY] doubleValue]];
    
    [self configureDimming];
}

//enable and disable the items
- (void)configureDimming
{	
    [delayField setEnabled:([enableBouncingCheckBox state] || [enableAnimationCheckBox state])];
    [bounceMatrix setEnabled:([enableBouncingCheckBox state] || [enableAnimationCheckBox state])];
    [bounceField setEnabled:
        ([[bounceMatrix selectedCell] tag] == 1 
        && ([enableBouncingCheckBox state] || [enableAnimationCheckBox state]))];
}   
@end
