/* CSWebAdium */

@class CSWebWindowController, CSWebTabViewItem;

@interface CSWebAdium : NSObject
{
	NSMutableArray				*webWindowControllerArray;
	CSWebWindowController		*lastUsedWebWindow;
}

- (void)transferWebTabContainer:(id)tabViewItem toWindow:(id)newWebWindow atIndex:(int)index withTabBarAtPoint:(NSPoint)screenPoint;
- (IBAction)createNewTab:(id)sender;
- (void)tabDidBecomeActive:(CSWebTabViewItem *)inTabViewItem;

@end
