//
//  LNStatusIconsPreferences.m
//  Adium
//
//  Created by Laura Natcher on Wed Oct 01 2003.
//

#import "LNStatusIconsPlugin.h"
#import "LNStatusIconsPreferences.h"


#define	STATUS_ICONS_PREF_NIB		@"StatusIconsPrefs"
#define STATUS_ICONS_PREF_TITLE		AILocalizedString(@"Status Icons Display",nil)

@interface LNStatusIconsPreferences (PRIVATE)
- (void)configureView;
@end

@implementation LNStatusIconsPreferences

+ (LNStatusIconsPreferences *)statusIconsPreferences
{
    return([[[self alloc] init] autorelease]);
}



- (IBAction)changePreference:(id)sender
{

    if(sender == checkBox_displayStatusIcons){
    
    	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
					     forKey:KEY_DISPLAY_STATUS_ICONS
					      group:PREF_GROUP_STATUS_ICONS];
    }

}


- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:STATUS_ICONS_PREF_TITLE]];

    return(self);
}


- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:STATUS_ICONS_PREF_NIB owner:self];

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

- (void)configureView
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_ICONS];

    [checkBox_displayStatusIcons setState:[[preferenceDict objectForKey:KEY_DISPLAY_STATUS_ICONS] boolValue]];

}



@end
