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

#import "AIBorderlessListWindowController.h"

@interface AIBorderlessListWindowController (PRIVATE)
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification;
@end

@implementation AIBorderlessListWindowController

//Init
- (id)init
{
	if((self = [super init]))
	{
		//Unlike a normal window, the system doesn't assist us in keeping the borderless contact list on a visible screen
		//So we'll observe screen changes and ensure that the contact list stays on a valid screen
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(centerWindowOnMainScreenIfNeeded:) 
																   name:NSApplicationDidChangeScreenParametersNotification 
																 object:nil];
	}

	return self;
}

- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}

//Borderless nib
- (NSString *)nibName
{
    return(@"ContactListWindowBorderless");    
}

//Ensure we're on the main screen on load
- (void)windowDidLoad
{
	[super windowDidLoad];
	[self centerWindowOnMainScreenIfNeeded:nil];
}	

//If our window is no longer on a screen, move it to the main screen and center
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification
{
	if(![[self window] screen]){
		[[self window] setFrameOrigin:[[NSScreen mainScreen] frame].origin];
		[[self window] center];
	}
}

@end
