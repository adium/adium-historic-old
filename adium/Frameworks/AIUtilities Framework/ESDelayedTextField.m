//
//  ESDelayedTextField.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

#import "ESDelayedTextField.h"

//  A text field that groups changes, sending its action to its target when 0.5 seconds elapses without a change

@interface ESDelayedTextField (PRIVATE)
- (id)_init;
- (void)_delayedAction:(NSTimer *)timer;
@end

@implementation ESDelayedTextField

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _init];
    return(self);
}

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	[self _init];	
	return self;
}

- (id)_init
{
	delayedChangesTimer = nil;

	return self;
}

- (void)fireImmediately
{
    if(delayedChangesTimer){
        if([delayedChangesTimer isValid]){
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
	
    if(delayedChangesTimer){
        if([delayedChangesTimer isValid]){
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
    
    delayedChangesTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(_delayedAction:) 
                                                          userInfo:nil 
														   repeats:NO] retain];
}

- (void)_delayedAction:(NSTimer *)timer
{
	[[self target] performSelector:[self action] withObject:self];
}


@end
