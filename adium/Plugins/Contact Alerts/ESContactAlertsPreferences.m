//
//  ESContactAlertsPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

#import "ESContactAlertsPreferences.h"
#import "ESContactAlertsPlugin.h"
#import "ESContactAlerts.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define	ALERTS_PREF_NIB			@"ContactAlertsPrefs"
#define ALERTS_PREF_TITLE		@"Contact Alerts"

@interface ESContactAlertsPreferences (PRIVATE)
-(id)initWithOwner:(id)inOwner;
-(void)configureView;
@end

@implementation ESContactAlertsPreferences
+ (ESContactAlertsPreferences *)contactAlertsPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];
   
    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Alerts withDelegate:self label:ALERTS_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:ALERTS_PREF_NIB owner:self];

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
}


@end
