//
//  JSCEventBezelPreferences.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

@interface JSCEventBezelPreferences : AIPreferencePane {
    IBOutlet NSButton *checkBox_showBezel;
    IBOutlet NSPopUpButton *popUp_position;
}

- (IBAction)toggleShowBezel:(id)sender;
- (IBAction)changePosition:(id)sender;

@end
