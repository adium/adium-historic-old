#import "CSWebAdium.h"
#import "CSWebWindowController.h"

#define TAB_CELL_IDENTIFIER     @"Tab Cell Identifier"

@interface CSWebWindowController (PRIVATE)

- (id)initWithWindowNibName:(NSString *)windowNibName interface:(id)inInterface;


@end

@implementation CSWebWindowController

+ (CSWebWindowController *)webWindowControllerForInterface:(id)inInterface;
{
	return [[[self alloc] initWithWindowNibName:@"WebWindow" interface:inInterface] autorelease];
}

- (id)initWithWindowNibName:(NSString *)windowNibName interface:(id)inInterface
{
	if (self = [super initWithWindowNibName:windowNibName]) {
		interface = [inInterface retain];
		[self window];
		[[self window] registerForDraggedTypes:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];
	}
	return self;
}

- (void)dealloc
{
    //During a drag, the tabs will not get deallocated on occasion, so we must make sure that we are no longer set as their delegate
    [customTabsView setDelegate:nil];
	
    [interface release];
	
    [super dealloc];
}


- (void)windowDidLoad
{
    //Remember the initial tab height
    tabHeight = [customTabsView frame].size.height;
	windowIsClosing = NO;
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
	
    //Remove any tabs from our tab view, it needs to start out empty
    while([tabView numberOfTabViewItems] > 0){
        [tabView removeTabViewItem:[tabView tabViewItemAtIndex:0]];
    }
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Close down
    windowIsClosing = YES; //This is used to prevent sending more close commands than needed.

    [interface tabDidBecomeActive:nil];
	
    return(YES);
}

//
- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [interface tabDidBecomeActive:(CSWebTabViewItem *)[tabView selectedTabViewItem]];
}

//
- (void)windowDidResignMain:(NSNotification *)notification
{
    [interface tabDidBecomeActive:nil];
}

- (IBAction)closeWindow:(id)sender
{
    [[self window] performClose:nil];
}

- (AICustomTabsView *)customTabsView
{
	return customTabsView;
}

- (CSWebTabViewItem *)selectedTabViewItemContainer
{
	return (CSWebTabViewItem *)[tabView selectedTabViewItem];
}

- (void)selectTabViewItemContainer:(CSWebTabViewItem *)inTabViewItem
{
	[self showWindow:nil];
	
    if(inTabViewItem){
        [tabView selectTabViewItem:(NSTabViewItem*)inTabViewItem];
    }
}

- (void)addTabViewItem:(CSWebTabViewItem*)inTabViewItem
{
	[self addTabViewItem:inTabViewItem atIndex:-1];
}

- (void)addTabViewItem:(CSWebTabViewItem*)inTabViewItem atIndex:(int)index
{
	[self window];
	
	if (index == -1) {
        [tabView addTabViewItem:(NSTabViewItem*)inTabViewItem];    //Add the tab
    } else {
        [tabView insertTabViewItem:(NSTabViewItem*)inTabViewItem atIndex:index]; //Add the tab at the specified index
    }
	
    [self showWindow:nil];
}
- (void)removeTabViewItemContainer:(CSWebTabViewItem*)inTabViewItem
{
	[interface tabDidBecomeActive:nil];
	
	if((NSTabViewItem*)inTabViewItem == [tabView selectedTabViewItem]){
		[tabView selectNextTabViewItem:nil];
    }
	
    //Remove the tab and let the interface know a container closed
    [tabView removeTabViewItem:(NSTabViewItem*)inTabViewItem];
	
	if([tabView numberOfTabViewItems] == 0){
        if(!windowIsClosing){
            [self closeWindow:nil];
        }
    }
}

- (BOOL)containsContainer:(CSWebTabViewItem *)tabViewItem
{
	return([[self containerArray] indexOfObjectIdenticalTo:tabViewItem] != NSNotFound);
}

- (BOOL)selectNextTabViewItemContainer
{
	NSTabViewItem	*previousSelection = [tabView selectedTabViewItem];
	
    [self showWindow:nil];
    [tabView selectNextTabViewItem:nil];
	
    return([tabView selectedTabViewItem] != previousSelection); 
}

- (BOOL)selectPreviousTabViewItemContainer
{
	NSTabViewItem	*previousSelection = [tabView selectedTabViewItem];
	
    [self showWindow:nil];
    [tabView selectPreviousTabViewItem:nil];
	
    return([tabView selectedTabViewItem] != previousSelection);
}

- (void)selectFirstTabViewItemContainer
{
	[self showWindow:nil];
    [tabView selectFirstTabViewItem:nil];
}

- (void)selectLastTabViewItemContainer
{
	[self showWindow:nil];
    [tabView selectLastTabViewItem:nil];
}

- (NSArray *)containerArray
{
    return([tabView tabViewItems]);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];
    NSDragOperation	operation = NSDragOperationNone;
	
    if(sender == nil || type){
        //Show the tab bar
        
        //Bring our window to the front
        if(![[self window] isKeyWindow]){
            [[self window] makeKeyAndOrderFront:nil];
        }
        
        operation = NSDragOperationPrivate;
    }
	
    return (operation);
}

//Drag exited, disable suppression
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	
}

- (void)customTabView:(AICustomTabsView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if(tabViewItem != nil){
        if([[self window] isMainWindow]){ //If our window is main, set the newly selected container as active
            [interface tabDidBecomeActive:(CSWebTabViewItem*)tabViewItem];
        }
		
        //[self _updateWindowTitle]; //Reflect change in window title
    }
}

- (void)customTabView:(AICustomTabsView *)tabView didMoveTabViewItem:(NSTabViewItem *)tabViewItem toCustomTabView:(AICustomTabsView *)destTabView index:(int)index screenPoint:(NSPoint)point
{
    [interface transferWebTabContainer:(CSWebTabViewItem*)tabViewItem
							  toWindow:[[destTabView window] windowController]
							   atIndex:index
					 withTabBarAtPoint:point];
}

@end
