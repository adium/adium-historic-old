//
//  AIDualWindowPreferences.m
//  Adium
//
//  Created by Adam Iser on Sat Jul 12 2003.
//

#import "AIDualWindowPreferences.h"
#import "AIDualWindowInterfacePlugin.h"

@interface AIDualWindowPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIDualWindowPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_ContactList_General);
}
- (NSString *)label{
    return(AILocalizedString(@"General Appearance","Miscellaneous configuration of the interface appearance"));
}
- (NSString *)nibName{
    return(@"DualWindowPrefs");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_autoResize){
	//The preference changed notification sent out below will result in our preferencesChanged code being called.
	//That code will change the state of our main autoresizing checkbox (sender).  This will cause problems if
	//we're trying to use [sender state] in both of the setPreference calls below.  Instead, we must get the state
	//ahead of time to ensure it applies evenly to both preferences.
	BOOL	senderState = [sender state]; 
	
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:senderState]
                                             forKey:KEY_DUAL_RESIZE_VERTICAL
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:senderState]
                                             forKey:KEY_DUAL_RESIZE_HORIZONTAL
                                              group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    }
}

//Configure the preference view
- (void)viewDidLoad
{
    [checkBox_autoResize setAllowsMixedState:YES];
    
    [self preferencesChanged:nil];
    
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)viewWillClose
{
	[[adium notificationCenter] removeObserver:self];
}

//Keep the preferences current
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the Behavior set changed
        if(notification == nil || ([key isEqualToString:KEY_DUAL_RESIZE_VERTICAL]) || ([key isEqualToString:KEY_DUAL_RESIZE_HORIZONTAL]) ){
            NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
            
            BOOL vertical = [[preferenceDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
            BOOL horizontal = [[preferenceDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
            if (vertical && horizontal) {
                [checkBox_autoResize setState:NSOnState];
            } else if (vertical || horizontal) {
                [checkBox_autoResize setState:NSMixedState];
            } else 
                [checkBox_autoResize setState:NSOffState];
        }
    }
}

@end



