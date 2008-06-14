//
//  AIWebKitPreviewMessageViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/13/08.
//

#import <Cocoa/Cocoa.h>
#import "AIWebKitMessageViewController.h"

@interface AIWebKitPreviewMessageViewController : AIWebKitMessageViewController {
	id							preferencesChangedDelegate;
}

- (void)setPreferencesChangedDelegate:(id)inDelegate;

@end
