//
//  ESDebugWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/29/04.
//

#import "ESDebugWindowController.h"

#define	KEY_DEBUG_WINDOW_FRAME	@"Debug Window Frame"
#define	DEBUG_WINDOW_NIB		@"DebugWindow"

@interface ESDebugWindowController (PRIVATE)
- (void)addedDebugMessage:(NSString *)message;
- (IBAction)closeWindow:(id)sender;
@end

@implementation ESDebugWindowController

static ESDebugWindowController *sharedDebugWindowInstance = nil;

//Return the shared contact info window
+ (id)showDebugWindow
{
    //Create the window
    if(!sharedDebugWindowInstance){
        sharedDebugWindowInstance = [[self alloc] initWithWindowNibName:DEBUG_WINDOW_NIB];
    }
	
	//Configure and show window
	[sharedDebugWindowInstance showWindow:nil];
	
	return(sharedDebugWindowInstance);
}

+ (BOOL)debugWindowIsOpen
{
	return(sharedDebugWindowInstance != nil);
}

//Close the debug window
+ (void)closeDebugWindow
{
    if(sharedDebugWindowInstance){
        [sharedDebugWindowInstance closeWindow:nil];
    }
}

+ (void)addedDebugMessage:(NSString *)aDebugString
{
	if(sharedDebugWindowInstance) [sharedDebugWindowInstance addedDebugMessage:aDebugString];
}
- (void)addedDebugMessage:(NSString *)aDebugString
{
	[mutableDebugString appendString:aDebugString];
	if ((![aDebugString hasSuffix:@"\n"]) && (![aDebugString hasSuffix:@"\r"])){
		[mutableDebugString appendString:@"\n"];
	}
}

- (NSString *)adiumFrameAutosaveName
{
	return(KEY_DEBUG_WINDOW_FRAME);
}

//Setup the window before it is displayed
- (void)windowDidLoad
{    
	NSEnumerator	*enumerator;
	NSString		*aDebugString;

	[super windowDidLoad];

	//We store the reference to the mutableString of the textStore for efficiency
	mutableDebugString = [[[textView_debug textStorage] mutableString] retain];
	
	[scrollView_debug setAutoScrollToBottom:YES];

	//Load the logs which were added before the window was loaded
	enumerator = [[[adium debugController] debugLogArray] objectEnumerator];
	while(aDebugString = [enumerator nextObject]){
		[mutableDebugString appendString:aDebugString];
		if ((![aDebugString hasSuffix:@"\n"]) && (![aDebugString hasSuffix:@"\r"])){
			[mutableDebugString appendString:@"\n"];
		}
	}

	//On the next run loop, scroll to the bottom
	[scrollView_debug performSelector:@selector(scrollToBottom)
						   withObject:nil
						   afterDelay:0.001];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
	[super windowShouldClose:sender];
	
	//Close down
	[mutableDebugString release]; mutableDebugString = nil;
    [self autorelease]; sharedDebugWindowInstance = nil;
	
    return(YES);
}


@end
