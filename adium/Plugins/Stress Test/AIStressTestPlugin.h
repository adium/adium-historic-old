//
//  AIStressTestPlugin.h
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//

#define STRESS_TEST_SERVICE_IDENTIFIER  @"Stress Test"

@class AIServiceType;

@interface AIStressTestPlugin : AIPlugin <AIServiceController> {
    IBOutlet 	NSView		*view_preferences;

    AIServiceType		*handleServiceType;
}

@end
