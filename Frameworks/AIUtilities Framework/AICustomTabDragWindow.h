//
//  AICustomTabDragWindow.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 06 2004.
//

@class ESFloater;

@interface AICustomTabDragWindow : NSObject {
	NSImage				*floaterTabImage;
	NSImage				*floaterWindowImage;
	ESFloater			*dragTabFloater;
	ESFloater			*dragWindowFloater;
	BOOL				fullWindow;
	
	BOOL				useFancyAnimations;
}
@end

@interface AICustomTabDragWindow (PRIVATE_AICustomTabDraggingOnly)
+ (AICustomTabDragWindow *)dragWindowForCustomTabView:(AICustomTabsView *)inTabView cell:(AICustomTabCell *)inTabCell transparent:(BOOL)transparent;
- (void)setDisplayingFullWindow:(BOOL)fullWindow animate:(BOOL)animate;
- (void)moveToPoint:(NSPoint)inPoint;
- (void)closeWindow;
- (NSImage *)dragImage;
@end
