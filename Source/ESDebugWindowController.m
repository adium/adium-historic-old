/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ESDebugController.h"
#import "ESDebugWindowController.h"
#import <AIUtilities/AIAutoScrollView.h>

#define	KEY_DEBUG_WINDOW_FRAME	@"Debug Window Frame"
#define	DEBUG_WINDOW_NIB		@"DebugWindow"

@implementation ESDebugWindowController
#ifdef DEBUG_BUILD

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

- (void)addedDebugMessage:(NSString *)aDebugString
{
	[mutableDebugString appendString:aDebugString];
	if ((![aDebugString hasSuffix:@"\n"]) && (![aDebugString hasSuffix:@"\r"])){
		[mutableDebugString appendString:@"\n"];
	}
}
+ (void)addedDebugMessage:(NSString *)aDebugString
{
	if(sharedDebugWindowInstance) [sharedDebugWindowInstance addedDebugMessage:aDebugString];
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

	[[self window] setTitle:AILocalizedString(@"Adium Debug Log","Debug window title")];

	//On the next run loop, scroll to the bottom
	[scrollView_debug performSelector:@selector(scrollToBottom)
						   withObject:nil
						   afterDelay:0.001];
}

//Close the debug window
+ (void)closeDebugWindow
{
    if(sharedDebugWindowInstance){
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
}

#endif

@end
