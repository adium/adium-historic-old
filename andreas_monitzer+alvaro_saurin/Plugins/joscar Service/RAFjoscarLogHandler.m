//
//  RAFjoscarLogHandler.m
//  Adium
//
//  Created by Augie Fackler on 12/26/05.
//

#import "RAFjoscarLogHandler.h"
#import "RAFjoscarDebugController.h"

@implementation RAFjoscarLogHandler

- (void)setOut:(NSString *)string
{
#ifdef DEBUG_BUILD
	[[NSClassFromString(@"RAFjoscarDebugController") sharedDebugController] performSelectorOnMainThread:@selector(addMessage:)
																					  withObject:string
																				   waitUntilDone:NO];
#endif
}

@end
