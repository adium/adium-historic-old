#import "CSWebWindowController.h"
#import "CSWebAdium.h"
#import "CSWebViewController.h"
#import "CSWebTabViewItem.h"

@interface CSWebAdium (PRIVATE)

- (CSWebTabViewItem *)_createTab;
- (CSWebTabViewItem *)_createTabInWebWindowController:(CSWebWindowController *)webWindowController;
- (CSWebWindowController *)_webWindowForContainer:(CSWebTabViewItem *)container;
- (CSWebWindowController *)_primaryWebWindow;
- (CSWebWindowController *)_createWebWindow;
- (void)_destroyWebWindow:(CSWebWindowController *)inWindow;

@end

@implementation CSWebAdium

- (void)awakeFromNib
{
	webWindowControllerArray = [[NSMutableArray alloc] init];
	
	[self createNewTab:self];
}

//A tab was moved from one window to another
- (void)transferWebTabContainer:(id)tabViewItem toWindow:(id)newWebWindow atIndex:(int)index withTabBarAtPoint:(NSPoint)screenPoint
{
    CSWebWindowController 	*oldWebWindow;
    
    //Transfer container from one one window to another
    oldWebWindow = [self _webWindowForContainer:tabViewItem];
    if(oldWebWindow != newWebWindow){
        //Get the frame of the source window (We must do this before removing the tab, since removing a tab may destroy the source window)        
        //Remove the tab
        [tabViewItem retain];
        [oldWebWindow removeTabViewItemContainer:tabViewItem];
        
        if(!newWebWindow) {
			NSRect newFrame;
            newWebWindow = [self _createWebWindow];
			newFrame.origin = screenPoint;
			newFrame.size = [[oldWebWindow window] frame].size;
			[[newWebWindow window] setFrame:newFrame display:NO];
        }
        
        [(CSWebWindowController *)newWebWindow addTabViewItem:tabViewItem atIndex:index];
        [tabViewItem release];
    }
}

- (CSWebWindowController *)_webWindowForContainer:(NSTabViewItem *)container
{
    NSEnumerator 		*windowEnumerator = [webWindowControllerArray objectEnumerator];
    CSWebWindowController 	*webWindowController = nil;
	
    while(webWindowController = [windowEnumerator nextObject]){
        if([webWindowController containsContainer:(CSWebTabViewItem*)container]) break;
    }
	
    return(webWindowController);
}

- (IBAction)createNewTab:(id)sender;
{
	[[[self _createTab] webViewController] loadURL:[NSURL URLWithString:@"http://www.adiumx.com"]];
}

- (void)tabDidBecomeActive:(CSWebTabViewItem *)inTabViewItem
{
	lastUsedWebWindow = (CSWebWindowController *)[[[inTabViewItem tabView] window] windowController];
	[[lastUsedWebWindow window] setTitle:[inTabViewItem labelString]];
}


- (CSWebTabViewItem *)_createTab
{
	CSWebWindowController	*webWindowController;
	if(![webWindowControllerArray count]){
        webWindowController = nil;
	}else if(lastUsedWebWindow){
        webWindowController = lastUsedWebWindow;
	} else {
		webWindowController = [webWindowControllerArray objectAtIndex:0];
	}

	return([self _createTabInWebWindowController:webWindowController]);
}

- (CSWebTabViewItem *)_createTabInWebWindowController:(CSWebWindowController *)webWindowController
{
    CSWebTabViewItem			*newTabItem = nil;
	CSWebViewController			*newWebView;
	

    //Create the message window, view, and tab
    if(!webWindowController) webWindowController = [self _createWebWindow];
	
	newWebView = [CSWebViewController webViewController];
	
    newTabItem = [CSWebTabViewItem webTabWithView:newWebView];

    //Add it to the message window & rebuild the window menu
    [webWindowController addTabViewItem:newTabItem];
	
    return(newTabItem);
}

- (CSWebWindowController *)_primaryWebWindow
{
    if([webWindowControllerArray count] != 0){ //Use our first message window as the primary
        return([webWindowControllerArray objectAtIndex:0]);
    }else{
        return(nil);
    }
}

//Create a new message window
- (CSWebWindowController *)_createWebWindow
{    
    CSWebWindowController	*webWindowController = [CSWebWindowController webWindowControllerForInterface:self];
     
    //Add the messageWindowController to our array
    [webWindowControllerArray addObject:webWindowController];
    
    return(webWindowController);
}

//Destroy a message window
- (void)_destroyWebWindow:(CSWebWindowController *)inWindow
{
    //Remove window from our array
    [webWindowControllerArray removeObject:inWindow];
}

@end
