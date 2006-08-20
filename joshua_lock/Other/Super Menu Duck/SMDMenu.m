#import "SMDMenu.h"
#import "JLPresenceProtocol.h"

int main(void) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];
    SMDMenu *menu = [[SMDMenu alloc] init];
	[NSApp setDelegate: menu];
	
    [NSApp run];
	[pool release];
	
	return EXIT_SUCCESS;
}

@implementation SMDMenu

- (void) applicationDidFinishLaunching: (NSNotification *)notification
{ // Unused notification
	presenceRemote = nil;
	adiumIsRunning = NO;
	
	NSBundle *bundle = [NSBundle mainBundle];
	adiumImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"adium"
																		  ofType:@"png"]];
	adiumHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"adiumHighlight"
																				   ofType:@"png"]];
	adiumOfflineImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"adiumOffline"
																				 ofType:@"png"]];
	adiumOfflineHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"adiumOfflineHighlight"
																						  ofType:@"png"]];
	adiumRedImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"adiumRed"
																			 ofType:@"png"]];
	adiumRedHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"adiumRedHighlight"
																					  ofType:@"png"]];
	
	// Set up observers	
	notificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(adiumStarted:)
							   name:@"JL_AdiumRunning"
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(adiumClosing:)
							   name:@"JL_AdiumClosing"
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(adiumOnline:)
							   name:@"JL_AdiumOnline"
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(unviewedContentOn:)
							   name:@"JL_UnviewedOn"
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(unviewedContentOff:)
							   name:@"JL_UnviewedOff"
							 object:nil];
	
	// Notify that we are alive
	[notificationCenter postNotificationName:@"JL_SMDRunning" object:nil];
	
	// Draw a basic menu
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	[statusItem setHighlightMode:YES];
	theMenu = [[NSMenu alloc] init];
	[theMenu setAutoenablesItems:NO];
	[statusItem setMenu:theMenu];
	
	// Draw our default offline menu
	[self drawOfflineMenu];
}

- (void) dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
	[[statusItem statusBar] removeStatusItem:statusItem];
	[statusItem release];
	[theMenu release];	
	[adiumImage release];
	[adiumHighlightImage release];
	[adiumOfflineImage release];
	[adiumOfflineHighlightImage release];
	[adiumRedImage release];
	[adiumRedHighlightImage release];
	
	[super dealloc];
}

#pragma mark Notification Handlers

- (void)adiumStarted:(NSNotification *)note
{
	adiumIsRunning = YES;
	// Redraw menu with Adium's presence data
	[self connectToVend];
	[self drawOfflineMenu];
}

- (void)adiumClosing:(NSNotification *)note
{
	presenceRemote = nil;
	adiumIsRunning = NO;
	// Draw our default offline menu
	[self drawOfflineMenu];
}

- (void)adiumOnline:(NSNotification *)note
{
	[self drawOnlineMenu];
}

/*#pragma mark Menu Delegates

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem 
{
	return YES;
}*/

#pragma mark -

- (void)drawOfflineMenu
{
	NSMenuItem *tmpMenuItem;
	[self removeAllMenuItems];
	
	[statusItem setImage:adiumOfflineImage];
	[statusItem setAlternateImage:adiumOfflineHighlightImage];
	
	if (!adiumIsRunning) {
		tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Launch Adium"
																   action:@selector(launchAdium)
															keyEquivalent:@""];
		[tmpMenuItem setTarget:self];
		[tmpMenuItem setEnabled:YES];
	} else {
		tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Adium Running"
													   action:nil
												keyEquivalent:@""];
		[tmpMenuItem setTarget:nil];
		[tmpMenuItem setEnabled:NO];
	}
	[theMenu addItem:[NSMenuItem separatorItem]];
		
	tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Quit SMD"
															   action:@selector(quitSMD)
														keyEquivalent:@""];
	[tmpMenuItem setTarget:self];
	//[[tmpMenuItem target] validateMenuItem:tmpMenuItem];
	[tmpMenuItem setEnabled:YES];
}

- (void)drawOnlineMenu
{
	NSMenuItem					*tmpMenuItem;
	NSEnumerator				*enumerator;
	id<JLStatusObjectProtocol>	statusObject;
	
	[statusItem setImage:adiumImage];
	[statusItem setAlternateImage:adiumHighlightImage];
	
	[self removeAllMenuItems];
	
	// Status menu
	if (!presenceRemote) {
		// Try and make presenceRemote != nil
		[self connectToVend];
		if (!presenceRemote) { // For whatever reason connecting to the vend isn't working!?!
			NSLog(@"JLD: !presenceRemote :(");
			// FIXME: report an error!
			//exit(-1);
		}
	} else {
		NSLog(@"JLD: Attempting to retrieve array of JLStatusObjects");
		enumerator = [[presenceRemote statusObjectArray] objectEnumerator];
		while ((statusObject = [enumerator nextObject])) {
			tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:[statusObject title] 
														   action:@selector(activateStatus)
													keyEquivalent:@""];
		}
	}
	
	[theMenu addItem: [NSMenuItem separatorItem]];
	
	tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Bring Adium to Front"
															   action:@selector(bringAdiumToFront)
														keyEquivalent:@""];
	[tmpMenuItem setTarget:self];
	
	tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Quit Adium"
															   action:@selector(quitAdium)
														keyEquivalent:@""];
	[tmpMenuItem setTarget:self];
	//[[tmpMenuItem target] validateMenuItem:tmpMenuItem];
	[tmpMenuItem setEnabled:YES];
	[theMenu addItem:[NSMenuItem separatorItem]];
	
	tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Quit SMD"
												   action:@selector(quitSMD)
											keyEquivalent:@""];
	[tmpMenuItem setTarget:self];
	//[[tmpMenuItem target] validateMenuItem:tmpMenuItem];
	[tmpMenuItem setEnabled:YES];
}

- (void)removeAllMenuItems
{
	int count = [theMenu numberOfItems];
	while (count--) {
		[theMenu removeItemAtIndex:0];
	}
}

- (void)quitSMD
{
	// FIXME: this seems a bit brutal?
	[NSApp terminate:self];
}

- (void)quitAdium
{
	[notificationCenter postNotificationName:@"JL_QuitAdium" object:nil];
}

- (void)launchAdium
{
	// FIXME: This launches *an* instance of Adium ... Refine :]
	[[NSWorkspace sharedWorkspace] launchApplication:@"Adium"];
}

- (void)unviewedContentOn:(NSNotification *)note
{
	[statusItem setImage:adiumRedImage];
	[statusItem setAlternateImage:adiumRedHighlightImage];
}

- (void)unviewedContentOff:(NSNotification *)note
{
	[statusItem setImage:adiumImage];
	[statusItem setAlternateImage:adiumHighlightImage];
}

- (void)bringAdiumToFront
{
	[notificationCenter postNotificationName:@"JL_BringAdiumFront" object:nil];
}

- (void)connectToVend
{
	if (!presenceRemote){
		presenceRemote = (id <JLPresenceRemoteProtocol>)[NSConnection rootProxyForConnectionWithRegisteredName:ADIUM_PRESENCE_BROADCAST
																										  host:nil];
		if (presenceRemote == nil) {
			NSLog(@"JLD: could not connect to vend");
			exit(1);
		} else {
			NSLog(@"JLD: Connected - woot!\n");
		}
	}
}

- (void)activateStatus
{
	
}

@end
