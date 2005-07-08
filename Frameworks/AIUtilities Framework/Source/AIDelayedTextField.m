//
//  AIDelayedTextField.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

#import "AIDelayedTextField.h"

//  A text field that groups changes, sending its action to its target when 0.5 seconds elapses without a change

@interface AIDelayedTextField (PRIVATE)
- (id)_init;
- (void)_delayedAction:(NSTimer *)timer;
@end

@implementation AIDelayedTextField

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self = [self _init];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _init];
	}
	return self;
}

- (id)_init
{
	delayedChangesTimer = nil;
	delayInterval = 0.5;
	
	return self;
}

- (void)setDelayInterval:(float)inInterval
{
	delayInterval = inInterval;
}
- (float)delayInterval
{
	return delayInterval;
}

- (void)fireImmediately
{
    if (delayedChangesTimer) {
        if ([delayedChangesTimer isValid]) {
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
		
		//Perform the timer action immediately
		[self _delayedAction:nil];
    }	
}

- (void)textDidChange:(NSNotification *)notification
{
	[super textDidChange:notification];
	
    if (delayedChangesTimer) {
        if ([delayedChangesTimer isValid]) {
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
    
    delayedChangesTimer = [[NSTimer scheduledTimerWithTimeInterval:delayInterval
                                                            target:self
                                                          selector:@selector(_delayedAction:) 
                                                          userInfo:nil 
														   repeats:NO] retain];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	//Don't trigger our delayed changes timer after the field ends editing.
	if (delayedChangesTimer) {
        if ([delayedChangesTimer isValid]) {
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
	
	[super textDidEndEditing:notification];
}

- (void)_delayedAction:(NSTimer *)timer
{
	[[self target] performSelector:[self action] withObject:self];

    if (delayedChangesTimer) {
        if ([delayedChangesTimer isValid]) {
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
}

@end
