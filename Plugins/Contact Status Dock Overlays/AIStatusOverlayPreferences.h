//
//  AIStatusOverlayPreferences.h
//  Adium
//
//  Created by Adam Iser on Mon Jun 23 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface AIStatusOverlayPreferences : AIPreferencePane {
    IBOutlet	NSButton	*checkBox_showStatusOverlays;
    IBOutlet	NSButton	*checkBox_showContentOverlays;
	
	IBOutlet	AILocalizationTextField	*label_showContacts;
}

@end