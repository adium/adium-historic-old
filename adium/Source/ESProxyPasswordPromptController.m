//
//  ESProxyPasswordPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 23 2004.
//

#import "ESProxyPasswordPromptController.h"

#define PROXY_PASSWORD_PROMPT_NIB		@"ProxyPasswordPrompt"

@interface ESProxyPasswordPromptController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector;
@end

@implementation ESProxyPasswordPromptController

+ (void)showPasswordPromptForProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
	ESProxyPasswordPromptController  *controller = [[[self alloc] initWithWindowNibName:PROXY_PASSWORD_PROMPT_NIB
																		 forProxyServer:inServer
																			   userName:inUserName
																		notifyingTarget:inTarget
																			   selector:inSelector] autorelease];
    //bring the window front
    [controller showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    [super initWithWindowNibName:windowNibName notifyingTarget:inTarget selector:inSelector];
    
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
    [textField_server setStringValue:server];
    [textField_userName setStringValue:userName];
	
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
