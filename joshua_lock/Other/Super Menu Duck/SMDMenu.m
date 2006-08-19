#import "SMDMenu.h"
//#import "JLAdiumDelegate.h"

#import <Adium/AIAccountMenu.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIAccount.h>

@class AIAdium;

// An attempt to satisafy Adium.frameworks NSParameterAssert(_sharedAdium != nil);
// I'm possibly expecting statics scope to be much wider than it is :( ... 
static AIAdium *_sharedAdium = nil;

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
{
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
	//[accountMenuItemsArray release];
	//[stateMenuItemsArray release];
	
	[super dealloc];
}

#pragma mark Notification Handlers

- (void)adiumStarted:(NSNotification *)note
{
	// Redraw menu with Adium's presence data
	
	[self connectToStatusVend];
	adium = [presenceRemote sharedAdiumInstance];
	_sharedAdium = adium;
	statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountStatusSubmenu
										   showTitleVerbs:NO] retain];
	//adiumDelegate = [[JLAdiumDelegate adiumDelegate] retain];
	[self drawOnlineMenu];
}

- (void)adiumClosing:(NSNotification *)note
{
	//[adiumDelegate release];
	_sharedAdium = nil;
	adium = nil;
	presenceRemote = nil;
	[accountMenu release];
	[statusMenu release];
	// Draw our default offline menu
	[self drawOfflineMenu];
}

#pragma mark Menu Delegates

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem 
{
	return YES;
}

#pragma mark Account Menu

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[accountMenuItemsArray release];
	accountMenuItemsArray = [menuItems retain];
	
	// FIXME: trigger update next time we're clicked
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	[inAccount toggleOnline];
}

#pragma mark State Menu

- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	[stateMenuItemsArray removeAllObjects];
	[stateMenuItemsArray addObjectsFromArray:menuItemArray];
	
	// FIXME: trigger update next time we're clicked
}

- (BOOL)showStatusSubmenu
{
	return YES;
}

#pragma mark -

- (void)drawOfflineMenu
{
	[self removeAllMenuItems];
	
	[statusItem setImage:adiumOfflineImage];
	[statusItem setAlternateImage:adiumOfflineHighlightImage];
	
	NSMenuItem *tmpMenuItem = (NSMenuItem *)[theMenu addItemWithTitle:@"Launch Adium"
															   action:@selector(launchAdium)
														keyEquivalent:@""];
	[tmpMenuItem setTarget:self];
	[tmpMenuItem setEnabled:YES];
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
	NSMenuItem		*tmpMenuItem;
	NSEnumerator	*enumerator;
	
	[self removeAllMenuItems];
	
	[statusItem setImage:adiumImage];
	[statusItem setAlternateImage:adiumHighlightImage];
	
	// Status menu
	/*if (!statusRemote)
		[self connectToStatusVend];
	
	NSMutableArray	*statusMenuItems = [statusRemote statusMenuItemArray];
	// Iterate through array and add menu items
	NSEnumerator	*statusEnumerator = [statusMenuItems objectEnumerator];
	while ((tmpMenuItem = [statusEnumerator nextObject])) {
		[theMenu addItem:tmpMenuItem];
	}
	
	[theMenu addItem:[NSMenuItem separatorItem]];*/
	
	// state menu items
	enumerator = [stateMenuItemsArray objectEnumerator];
	tmpMenuItem = nil;
	while ((tmpMenuItem = [enumerator nextObject])) {
		NSMenu		*submenu;
		
		[theMenu addItem:tmpMenuItem];
		
		// FIXME: add menu validation here
		
		submenu = [tmpMenuItem submenu];
		if (submenu) {
			NSEnumerator	*submenuEnumerator = [[submenu itemArray] objectEnumerator];
			NSMenuItem		*submenuItem;
			while ((submenuItem = [submenuEnumerator nextObject])) {
				// FIXME: validate the submenu items
			}
		}
	}
	
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

- (void)connectToStatusVend
{
	presenceRemote = (id)[NSConnection rootProxyForConnectionWithRegisteredName:ADIUM_PRESENCE_BROADCAST
																		  host:nil];
	if (presenceRemote == nil) {
		// FIXME: handle this error!
		NSLog(@"JLD: presenceRemote == nil after we tried to connect...");
	}
}

@end
