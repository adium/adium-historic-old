//
//  CBGaimServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AIServiceType;


@interface CBGaimServicePlugin : AIPlugin <AIServiceController> {
        AIServiceType		*handleServiceType;
        
        IBOutlet 	NSView		*view_preferences;
}

@end
