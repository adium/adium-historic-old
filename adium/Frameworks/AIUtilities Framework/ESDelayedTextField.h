//
//  ESDelayedTextField.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

@interface ESDelayedTextField : NSTextField {
	NSTimer *delayedChangesTimer;
}

- (void)fireImmediately;

@end
