//
//  CBStatusMenuItemPreferences.h
//  Adium
//
//  Created by Colin Barrett on Thu Jul 15 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface CBStatusMenuItemPreferences : AIPreferencePane {
    IBOutlet    NSButton    *checkBox_enableStatusMenuItem;
}

- (IBAction)changePreference:(id)sender;

@end
