//
//  AIStressTestPlugin.h
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@class AIServiceType;

@interface AIStressTestPlugin : AIPlugin <AIServiceController> {
    IBOutlet 	NSView		*view_preferences;

    AIServiceType		*handleServiceType;
}

@end
