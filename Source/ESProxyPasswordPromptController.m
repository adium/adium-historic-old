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

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "ESProxyPasswordPromptController.h"
#import <AIUtilities/ESURLAdditions.h>

#define PROXY_PASSWORD_PROMPT_NIB		@"ProxyPasswordPrompt"

@interface ESProxyPasswordPromptController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;
@end

@implementation ESProxyPasswordPromptController

+ (void)showPasswordPromptForProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	ESProxyPasswordPromptController  *controller = [[[self alloc] initWithWindowNibName:PROXY_PASSWORD_PROMPT_NIB
																		 forProxyServer:inServer
																			   userName:inUserName
																		notifyingTarget:inTarget
																			   selector:inSelector
																				context:inContext] autorelease];
    //bring the window front
    [controller showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
    [super initWithWindowNibName:windowNibName notifyingTarget:inTarget selector:inSelector context:inContext];
    
    server = [inServer retain];
	userName = [inUserName retain];
	[self retain];
	
    return(self);
}

- (void)dealloc
{
    [server release];
	[userName release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
    [textField_server setStringValue:([server length] ? server : @"<None>")];
    [textField_userName setStringValue:([userName length] ? userName : @"<None>")];
	
	[super windowDidLoad];
}

- (NSString *)savedPasswordKey
{
	return @"SavedProxyPassword";
}

//Save a password; pass nil to forget the password
- (void)savePassword:(NSString *)password
{
	[[adium accountController] setPassword:password forProxyServer:server userName:userName];
}


@end
