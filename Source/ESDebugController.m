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

@interface ESDebugController (PRIVATE)
- (void)addMessage:(NSString *)actualMessage;
@end

@implementation ESDebugController

static NSMutableArray	*debugLogArray = nil;

- (void)initController
{
#ifdef DEBUG_BUILD
	//Contact list menu tem
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Debug Window",nil)
												   target:self
												   action:@selector(showDebugWindow:)
											keyEquivalent:@""] autorelease];
	[[owner menuController] addMenuItem:item toLocation:LOC_Adium_About];
	
	debugLogArray = [[NSMutableArray alloc] init];
	
	//Restore the debug window if it was open when we quit last time
	if ([[[owner preferenceController] preferenceForKey:KEY_DEBUG_WINDOW_OPEN
												  group:GROUP_DEBUG] boolValue]){
		[ESDebugWindowController showDebugWindow];
	}
#endif
}

- (void)closeController
{
	//Save the open state of the debug window
	[[owner preferenceController] setPreference:([ESDebugWindowController debugWindowIsOpen] ?
												 [NSNumber numberWithBool:YES] :
												 nil)
										 forKey:KEY_DEBUG_WINDOW_OPEN
										  group:GROUP_DEBUG];
	[ESDebugWindowController closeDebugWindow];
}

- (void)dealloc
{
	[debugLogArray release];
	[super dealloc];
}

- (void)showDebugWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[ESDebugWindowController showDebugWindow];
}

//Called via the AILog #define declaraed in AIAdium.h, takes a format string with a variable number of arguments
- (void)adiumDebug:(NSString *)message, ...
{
#ifdef DEBUG_BUILD
	va_list		ap; /* Points to each unamed argument in turn */
	NSString	*actualMessage;
	
	va_start(ap, message); /* Make ap point to the first unnamed argument */
	actualMessage = [[NSString alloc] initWithFormat:message
										   arguments:ap];
	
	/* Be careful; we should only modify debugLogArray and the windowController's view on the main thread. */
	[self performSelectorOnMainThread:@selector(addMessage:)
						   withObject:actualMessage
						waitUntilDone:NO];

	[actualMessage release];
	va_end(ap); /* clean up when done */
#endif
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

@end
