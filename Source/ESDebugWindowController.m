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
	
	return (sharedDebugWindowInstance);
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

//Close the info window
+ (void)closeInfoWindow
{
    if(sharedDebugWindowInstance){
        [sharedDebugWindowInstance closeWindow:nil];
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

	mutableDebugString = [[[textView_debug textStorage] mutableString] retain];
	[scrollView_debug setAutoScrollToBottom:YES];
	
	enumerator = [[[adium debugController] debugLogArray] objectEnumerator];
	while(aDebugString = [enumerator nextObject]){
		[mutableDebugString appendString:aDebugString];
		if ((![aDebugString hasSuffix:@"\n"]) && (![aDebugString hasSuffix:@"\r"])){
			[mutableDebugString appendString:@"\n"];
		}
	}
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
