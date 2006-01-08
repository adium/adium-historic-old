//
//  ESGaimOTRPrivateKeyGenerationWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESGaimOTRPrivateKeyGenerationWindowController : AIWindowController {
	IBOutlet	NSProgressIndicator	*progressIndicator;
	IBOutlet	NSTextField			*textField_message;
	
	NSString	*identifier;
}

+ (void)startedGeneratingForIdentifier:(NSString *)identifier;
+ (void)finishedGeneratingForIdentifier:(NSString *)identifier;

@end
