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

    //Observer preference changes
//    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Configure the view and load our preferences
//    [self configureView];
//    [self preferencesChanged:nil];

    return(self);
}

@end
