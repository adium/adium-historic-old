//
//  ESDelayedTextField.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

@interface ESDelayedTextField : NSTextField {
	NSTimer *delayedChangesTimer;
	float   delayInterval;
}

- (void)fireImmediately;

- (void)setDelayInterval:(float)inInterval;
- (float)delayInterval;

@end
