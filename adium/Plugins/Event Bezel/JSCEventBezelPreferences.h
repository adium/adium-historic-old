//
//  JSCEventBezelPreferences.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

@interface JSCEventBezelPreferences : AIPreferencePane {
    IBOutlet NSButton *checkBox_showBezel;
}

- (IBAction)toggleShowBezel:(id)sender;

@end
