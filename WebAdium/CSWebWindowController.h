@class CSWebAdium, CSWebTabViewItem;

@interface CSWebWindowController : NSWindowController {
	IBOutlet AICustomTabsView *customTabsView;
	IBOutlet NSTabView		 *tabView;
	float			tabHeight;
	BOOL			windowIsClosing;
	
	CSWebAdium 	*interface;
}

+ (CSWebWindowController *)webWindowControllerForInterface:(id)inInterface;
- (IBAction)closeWindow:(id)sender;

- (CSWebTabViewItem *)selectedTabViewItemContainer;
- (void)selectTabViewItemContainer:(CSWebTabViewItem *)inTabViewItem;
- (void)addTabViewItem:(CSWebTabViewItem*)inTabViewItem;
- (void)addTabViewItem:(CSWebTabViewItem*)inTabViewItem atIndex:(int)index;
- (void)removeTabViewItemContainer:(CSWebTabViewItem*)inTabViewItem;
- (BOOL)containsContainer:(CSWebTabViewItem *)tabViewItem;
- (BOOL)selectNextTabViewItemContainer;
- (BOOL)selectPreviousTabViewItemContainer;
- (void)selectFirstTabViewItemContainer;
- (void)selectLastTabViewItemContainer;
- (NSArray *)containerArray;
- (AICustomTabsView *)customTabsView;
@end
