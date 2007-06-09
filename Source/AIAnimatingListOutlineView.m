//
//  AIAnimatingListOutlineView.m
//  Adium
//
//  Created by Evan Schoenberg on 6/8/07.
//

#import "AIAnimatingListOutlineView.h"
#import "AIOutlineViewAnimation.h"
#import <Adium/AIObject.h>

@interface AIAnimatingListOutlineView (PRIVATE)
- (NSRect)unanimatedRectOfRow:(int)rowIndex;
@end

/*!
 * @class
 * @brief An outline view which animates changes to its order
 *
 * Implementation inspired by Dan Wood's AnimatingTableView in TableTester, http://gigliwood.com/tabletester/
 */
@implementation AIAnimatingListOutlineView
/*
 * @brief Return the current rect for a row
 *
 * If we're animating, this is somewhere between (progress % between) the old and new rects.
 * If we're not, pass it to super.
 */
- (NSRect)rectOfRow:(int)rowIndex
{
	if (animations > 0) {
		id thisItem = [self itemAtRow:rowIndex];
		NSDictionary *animDict = [allAnimatingItemsDict objectForKey:[NSValue valueWithPointer:thisItem]];
		if (animDict) {
			int oldIndex = [[animDict objectForKey:@"old index"] intValue];
			float progress = [[animDict objectForKey:@"progress"] floatValue];
			NSRect oldR = [self unanimatedRectOfRow:oldIndex];
			NSRect newR = [self unanimatedRectOfRow:rowIndex];
			
			//Calculate a rectangle between the original and the final rectangles.
			NSRect newRect = NSMakeRect(NSMinX(oldR) + (progress * (NSMinX(newR) - NSMinX(oldR))),
										NSMinY(oldR) + (progress * (NSMinY(newR) - NSMinY(oldR))),
										NSWidth(newR), NSHeight(newR) );
			return newRect;

		} else {
			return [super rectOfRow:rowIndex];			
		}
	} else {
		return [super rectOfRow:rowIndex];
	}
}

/*!
 * @brief Rect of the row if we weren't animating
 */
- (NSRect)unanimatedRectOfRow:(int)rowIndex
{
	return [super rectOfRow:rowIndex];
}

/*
 * @brief If we're animating, all rows are within any given rect, since we don't know where they are.
 *
 * XXX Is this necessary?
 */
- (NSRange)rowsInRect:(NSRect)inRect
{
	if (animations > 0) {
		return NSMakeRange(0, [self numberOfRows]);		
	} else {
		return [super rowsInRect:inRect];
	}
}

/*
 * @brief Return a dictionary of indexes keyed by pointers to items for item and all children
 *
 * This function uses itself recursively; when calling from outside, dict should be nil.
 *
 * @result The dictionary
 */
- (NSMutableDictionary *)indexesForItemAndChildren:(id)item dict:(NSMutableDictionary *)dict
{
	if (!dict) dict = [NSMutableDictionary dictionary];
	if (!item || ([self isExpandable:item] &&
				  [self isItemExpanded:item])) {
		int numChildren = [[self dataSource] outlineView:self numberOfChildrenOfItem:item];
		//Add each child
		for (int i = 0; i < numChildren; i++) {
			id thisChild = [[self dataSource] outlineView:self child:i ofItem:item];
			dict = [self indexesForItemAndChildren:thisChild dict:dict];
		}
	}

	int index = [self rowForItem:item];
	if (index != -1) [dict setObject:[NSNumber numberWithInt:index] forKey:[NSValue valueWithPointer:item]];

	return dict;
}

/*!
 * @brief Create a dictionary of the current indexes, keyed by items, and configure before an animation starts
 *
 * Every row, regardles of whether it has changed (which we don't know yet), starts off at its current index ("old index")
 * with a progress of 0% towards its new index.
 *
 * This is called before allowing super to perform an update.
 * 
 * @result A dictionary of indexes keyed by pointers to items
 */
- (NSDictionary *)saveCurrentIndexesForItem:(id)item
{
	NSEnumerator *enumerator;
	id oldItem;

	NSDictionary *oldDict = [self indexesForItemAndChildren:item dict:nil];

	if (!allAnimatingItemsDict) allAnimatingItemsDict  = [[NSMutableDictionary alloc] init];

	enumerator = [oldDict keyEnumerator];
	while ((oldItem = [enumerator nextObject])) {
		NSNumber *oldIndex = [oldDict objectForKey:oldItem];
		[allAnimatingItemsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			oldIndex, @"old index",
			[NSNumber numberWithFloat:0.0f], @"progress", nil]
								  forKey:oldItem];			
	}
	
	animations++;

	return oldDict;
}

/*!
 * @brief Given old indexes, after an update has occurred, determine what needs to be animated
 *
 * Any item which is not at the same row as it was in oldDict has changed. 
 * allAnimatingItemsDict already has this item at 0% from the old row towards its new row.
 *
 * If the item has not changed, immediately set it to 100% progress.
 *
 * Finally, create and start an AIOutlineViewAnimation which will notify us as the animation progresses.
 */
- (void)updateForNewIndexesFromOldIndexes:(NSDictionary *)oldDict forItem:(id)item
{
	NSEnumerator *enumerator;
	id oldItem;
	NSDictionary *newDict = [self indexesForItemAndChildren:item dict:nil];
	NSMutableDictionary *animatingRowsDict = [NSMutableDictionary dictionary];

	//Compare differences
	enumerator = [oldDict keyEnumerator];
	while ((oldItem = [enumerator nextObject])) {
		NSNumber *oldIndex = [oldDict objectForKey:oldItem];
		NSNumber *newIndex = [newDict objectForKey:oldItem];
		if (newIndex && ([oldIndex intValue] != [newIndex intValue])) {
			[animatingRowsDict setObject:oldIndex
								  forKey:oldItem];
			/*
			 [allAnimatingItemsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
				 oldIndex, @"old index",
				 [NSNumber numberWithFloat:0.0f], @"progress", nil]
									   forKey:oldItem];
			 */
		} else {
			[allAnimatingItemsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
				oldIndex, @"old index",
				[NSNumber numberWithFloat:1.0f], @"progress", nil]
									  forKey:oldItem];			
		}
	}
	
	if ([animatingRowsDict count]) {
		AIOutlineViewAnimation *animation = [AIOutlineViewAnimation listObjectAnimationWithDictionary:animatingRowsDict delegate:self];
		animations++;
		[animation startAnimation];
		//Will be released in animationDidEnd:
		[animation retain];
	} else {
		animations--;
	}
}

#pragma mark AIListObjectAnimation callbacks

/*
 * @brief The animation for some rows (animatingRowsDict) has progressed
 *
 * Update the progress for those rows as tracked in allAnimatingItemsDict, then display.
 *
 * XXX Possible efficiency: Only display the needed rect?
 */
- (void)animation:(AIOutlineViewAnimation *)animation didSetCurrentValue:(float)currentValue forDict:(NSDictionary *)animatingRowsDict
{
	NSEnumerator *enumerator = [animatingRowsDict keyEnumerator];
	id item;
	
	while ((item = [enumerator nextObject])) {
		NSNumber *oldIndex = [[allAnimatingItemsDict objectForKey:item] objectForKey:@"old index"];
		
		[allAnimatingItemsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			oldIndex, @"old index",
			[NSNumber numberWithFloat:currentValue], @"progress", nil]
								  forKey:item];
	}
	
	[self display];
}

- (void)animationDidEnd:(NSAnimation*)animation
{
	animations--;
	[animation release];
}

#pragma mark Intercepting changes so we can animate

- (void)reloadData
{
	NSDictionary *oldDict = [self saveCurrentIndexesForItem:nil];
	[super reloadData];
	[self updateForNewIndexesFromOldIndexes:oldDict forItem:nil];	
}

- (void)reloadItem:(id)item reloadChildren:(BOOL)reloadChildren
{
	NSDictionary *oldDict = [self saveCurrentIndexesForItem:item];
	[super reloadItem:item reloadChildren:reloadChildren];
	[self updateForNewIndexesFromOldIndexes:oldDict forItem:item];
}

- (void)reloadItem:(id)item
{
	NSDictionary *oldDict = [self saveCurrentIndexesForItem:item];
	[super reloadItem:item];
	[self updateForNewIndexesFromOldIndexes:oldDict forItem:item];
}

@end
