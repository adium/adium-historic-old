//
//  ESDebugController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/27/04.
//

#import "ESDebugController.h"
#import "ESDebugWindowController.h"

#define	CACHED_DEBUG_LOGS		100		//Number of logs to keep at any given time
#define	KEY_DEBUG_WINDOW_OPEN	@"Debug Window Open"
#define	GROUP_DEBUG				@"Debug Group"

@implementation ESDebugController

#ifdef DEBUG_BUILD

static ESDebugController	*sharedDebugController = nil;

- (void)initController
{
	sharedDebugController = self;
	
	//Contact list menu tem
    NSMenuItem *item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Debug Window",nil)
																			 target:self
																			 action:@selector(showDebugWindow:)
																	  keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:item toLocation:LOC_Adium_About];
	
	debugLogArray = [[NSMutableArray alloc] init];
	
	//Restore the debug window if it was open when we quit last time
	if ([[[adium preferenceController] preferenceForKey:KEY_DEBUG_WINDOW_OPEN
												  group:GROUP_DEBUG] boolValue]){
		[ESDebugWindowController showDebugWindow];
	}
}

- (void)closeController
{
	//Save the open state of the debug window
	[[adium preferenceController] setPreference:([ESDebugWindowController debugWindowIsOpen] ?
												 [NSNumber numberWithBool:YES] :
												 nil)
										 forKey:KEY_DEBUG_WINDOW_OPEN
										  group:GROUP_DEBUG];
	[ESDebugWindowController closeDebugWindow];
}

+ (ESDebugController *)sharedDebugController
{
	return sharedDebugController;
}

- (void)dealloc
{
	[debugLogArray release];
	sharedDebugController = nil;
	[super dealloc];
}

- (void)showDebugWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[ESDebugWindowController showDebugWindow];
}

- (void)addMessage:(NSString *)actualMessage
{
	[debugLogArray addObject:actualMessage];
	
	//Keep debugLogArray to a reasonable size
	if ([debugLogArray count] > CACHED_DEBUG_LOGS) [debugLogArray removeObjectAtIndex:0];
	
	[ESDebugWindowController addedDebugMessage:actualMessage];
}

- (NSArray *)debugLogArray
{
	return(debugLogArray);
}

#else
	- (void)initController {};
	- (void)closeController {};
#endif /* DEBUG_BUILD */

@end
