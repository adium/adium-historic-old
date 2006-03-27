//
//  RAFjoscarDebugWindowController.m
//  Adium
//
//  Created by Augie Fackler on 12/28/05.
//

#import "RAFjoscarDebugWindowController.h"
#import "RAFjoscarDebugController.h"
#import "AIPreferenceController.h"
#import "AIAdium.h"
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIStringUtilities.h>
#import "joscarClasses.h"

#define	KEY_DEBUG_WINDOW_FRAME	@"joscar Debug Window Frame"
#define	DEBUG_WINDOW_NIB		@"joscarDebugWindow"

@implementation RAFjoscarDebugWindowController
#ifdef DEBUG_BUILD

static RAFjoscarDebugWindowController *sharedDebugWindowInstance = nil;

//Return the shared contact info window
+ (id)showDebugWindow
{
    //Create the window
    if (!sharedDebugWindowInstance) {
        sharedDebugWindowInstance = [[self alloc] initWithWindowNibName:DEBUG_WINDOW_NIB];
    }
	//Configure and show window
	[sharedDebugWindowInstance showWindow:nil];
	
	return sharedDebugWindowInstance;
}

+ (BOOL)debugWindowIsOpen
{
	return sharedDebugWindowInstance != nil;
}

- (void)addedDebugMessage:(NSString *)aDebugString
{
	[mutableDebugString appendString:aDebugString];
}
+ (void)addedDebugMessage:(NSString *)aDebugString
{
	if (sharedDebugWindowInstance) [sharedDebugWindowInstance addedDebugMessage:aDebugString];
}

- (NSString *)adiumFrameAutosaveName
{
	return KEY_DEBUG_WINDOW_FRAME;
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
	enumerator = [[[RAFjoscarDebugController sharedDebugController] debugLogArray] objectEnumerator];
	while ((aDebugString = [enumerator nextObject])) {
		[mutableDebugString appendString:aDebugString];
		if ((![aDebugString hasSuffix:@"\n"]) && (![aDebugString hasSuffix:@"\r"])) {
			[mutableDebugString appendString:@"\n"];
		}
	}
	
	[[self window] setTitle:AILocalizedString(@"Adium joscar Debug Log","Debug window title")];
	
	//On the next run loop, scroll to the bottom
	[scrollView_debug performSelector:@selector(scrollToBottom)
						   withObject:nil
						   afterDelay:0.001];
	
	[checkBox_logWriting setState:[[[adium preferenceController] preferenceForKey:KEY_JOSCAR_DEBUG_WRITE_LOG
																			group:GROUP_JOSCAR_DEBUG] boolValue]];
	
	NSString	*javaVersion = [NSClassFromString(@"java.lang.System") getProperty:@"java.version"];
	
	if (javaVersion) {
		[textView_version setStringValue:[NSString stringWithFormat:@"Java version: %@, joscar version: %@", 
			javaVersion,
			[NSClassFromString(@"net.kano.joscar.JoscarTools") getVersionString]]];
	} else {
		[textView_version setStringValue:[NSString stringWithFormat:@"Java not loaded"]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(attachedJavaVM:)
													 name:@"AttachedJavaVM"
												   object:nil];
	}
}

/*
 * @brief Java VM was attached
 *
 * Update our displayed version info
 */
- (void)attachedJavaVM:(NSNotification *)inNotification
{
	[textView_version setStringValue:[NSString stringWithFormat:@"Java version: %@, joscar version: %@", 
		[NSClassFromString(@"java.lang.System") getProperty:@"java.version"],
		[NSClassFromString(@"net.kano.joscar.JoscarTools") getVersionString]]];
}

//Close the debug window
+ (void)closeDebugWindow
{
    if (sharedDebugWindowInstance) {
        [sharedDebugWindowInstance closeWindow:nil];
    }
}

//called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	//Close down
	[mutableDebugString release]; mutableDebugString = nil;
    [self autorelease]; sharedDebugWindowInstance = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)toggleLogWriting:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
										 forKey:KEY_JOSCAR_DEBUG_WRITE_LOG
										  group:GROUP_JOSCAR_DEBUG];
}

- (IBAction)clearLog:(id)sender
{
	[mutableDebugString setString:@""];
	[[RAFjoscarDebugController sharedDebugController] clearDebugLogArray];
	
	[scrollView_debug scrollToTop];
}

#endif
@end
