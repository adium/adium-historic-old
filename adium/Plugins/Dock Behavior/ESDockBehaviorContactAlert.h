//
//  ESDockBehaviorContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//

#import "AIDockBehaviorPlugin.h"


@interface ESDockBehaviorContactAlert : ESContactAlert {
    IBOutlet	NSView			*view_details_menu;
    IBOutlet	NSPopUpButton		*popUp_actionDetails;
    
    NSMenu      *behaviorListMenu_cached;
}

@end
