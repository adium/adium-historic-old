//
//  ESEventSoundContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIEventSoundsPlugin.h"

@interface ESEventSoundAlertDetailPane : AIActionDetailsPane {
    IBOutlet	NSPopUpButton		*popUp_actionDetails;

	NSImage		*soundFileIcon;
	
	IBOutlet	AILocalizationTextField	*label_sound;
}

@end
