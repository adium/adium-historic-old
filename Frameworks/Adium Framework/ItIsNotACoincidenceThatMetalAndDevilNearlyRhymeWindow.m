//
//  ItIsNotACoincidenceThatMetalAndDevilNearlyRhymeWindow.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Jun 30 2004.
//

/*
 Friends don't let friends use metal.  If this class is in your project, it means you've taken responsibility
for the actions of others, following only the true, Aqua path to peace, justive, and a bigger slice of the pizza pie.
*/

#import "ItIsNotACoincidenceThatMetalAndDevilNearlyRhymeWindow.h"

@implementation ItIsNotACoincidenceThatMetalAndDevilNearlyRhymeWindow

+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass:[NSWindow class]];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	//Cancel out any attempt to create Windows Of Satan.
	if (styleMask & NSTexturedBackgroundWindowMask){
		styleMask &= ~NSTexturedBackgroundWindowMask;
	}

	//Otherwise, proceed as normal.
	return ([super initWithContentRect:contentRect
					 styleMask:styleMask
					   backing:backingType
						 defer:flag]);
}
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag screen:(NSScreen *)aScreen
{
	//Fight the good fight.
	if (styleMask & NSTexturedBackgroundWindowMask){
		styleMask &= ~NSTexturedBackgroundWindowMask;
	}

	//Otherwise, proceed as normal.
	return([super initWithContentRect:contentRect
					 styleMask:styleMask
					   backing:backingType
						 defer:flag
						screen:aScreen]);
}

@end
