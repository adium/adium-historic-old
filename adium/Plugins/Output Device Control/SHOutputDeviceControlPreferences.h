//
//  SHOutputDeviceControlPreferences.h
//  Adium
//
//  Created by Stephen Holt on Mon Apr 12 2004.



@interface SHOutputDeviceControlPreferences : AIPreferencePane {
    IBOutlet NSButton           *checkBox_useAlertOutput;
    IBOutlet NSView             *view_outputPrefView;
}

- (IBAction)changePreference:(id)sender;
@end
