//
//  ESEventSoundContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

#import "AIEventSoundsPlugin.h"

@interface ESEventSoundContactAlert : ESContactAlert {
    IBOutlet	NSView			*view_details_menu;
    IBOutlet	NSPopUpButton		*popUp_actionDetails;
    
    NSMenu      *soundMenu_cached;
}

@end
