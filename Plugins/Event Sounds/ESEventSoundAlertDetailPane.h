//
//  ESEventSoundContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

#import "AIEventSoundsPlugin.h"

@interface ESEventSoundAlertDetailPane : AIActionDetailsPane {
    IBOutlet	NSPopUpButton		*popUp_actionDetails;

	NSImage		*soundFileIcon;
}

@end
