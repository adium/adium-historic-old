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
#import "AIContactController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListCell.h>
#import <Adium/AIListOutlineView.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradient.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIEventAdditions.h>
#import "AISCLViewPlugin.h"

#define MINIMUM_HEIGHT				48

@interface AIListOutlineView (PRIVATE)
- (void)_initListOutlineView;
@end

@implementation AIListOutlineView

+ (void)initialize
{
	[self exposeBinding:@"desiredHeight"];
	[self exposeBinding:@"totalHeight"];
	[self setKeys:[NSArray arrayWithObject:@"totalHeight"] triggerChangeNotificationsForDependentKey:@"desiredHeight"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initListOutlineView];
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
	
	[super initWithFrame:frame];
	[self _initListOutlineView];
	[self registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListContact",@"AIListObject",nil]];
	return self;
}

- (void)_initListOutlineView
{
	updateShadowsWhileDrawing = NO;
	
	backgroundImage = nil;
	backgroundFade = 1.0;
	backgroundColor = nil;
	backgroundStyle = AINormalBackground;
	
	unlockingGroup = NO;
	dragContent = nil;
	
	[self setDrawsGradientSelection:YES];
	[self sizeLastColumnToFit];	

	groupsHaveBackground = NO;
	
	[[[AIObject sharedAdiumInstance] preferenceController] registerPreferenceObserver:self
																			 forGroup:PREF_GROUP_LIST_THEME];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setUnlockGroup:)
												 name:@"AIListOutlineViewUnlockGroup" 
											   object:nil];


}

- (void)dealloc
{	
	[[[AIObject sharedAdiumInstance] preferenceController] unregisterPreferenceObserver:self];
	
	[backgroundImage release];
	[backgroundColor release];
	[self unregisterDraggedTypes];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)preferencesChangedForGroup:(NSString *)group 
							   key:(NSString *)key
							object:(AIListObject *)object 
					preferenceDict:(NSDictionary *)prefDict 
						 firstTime:(BOOL)firstTime
{
	if (object != nil)
		return;
	
	groupsHaveBackground = [[prefDict objectForKey:KEY_LIST_THEME_GROUP_GRADIENT] boolValue];
}

//Prevent the display of a focus ring around the contact list in 10.3 and greater
- (NSFocusRingType)focusRingType
{
    return NSFocusRingTypeNone;
}

//When our delegate is set, ask it for our data cells
- (void)setDelegate:(id)delegate
{
	[super setDelegate:delegate];
}

//Keep our column full width
- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[self sizeLastColumnToFit];
}

//Selection Hiding -----------------------------------------------------------------------------------------------------
//If our window isn't in the foreground, we're not displaying a selection.  So override this method to pass NO for
//selected in that situation
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
	if (![[self window] isKeyWindow]) selected = NO;
	[super _drawRowInRect:rect colored:colored selected:selected];
}
	
//When our view is inserted into a window, observe that window so we can hide selection when it's not main
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if ([newSuperview window]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:[newSuperview window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:[newSuperview window]];
    }
}

//Redraw our cells so they can select or de-select
- (void)windowBecameMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}
- (void)windowResignedMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}

//
- (void)cancelOperation:(id)sender
{
	[self deselectAll:nil];
}

//Sizing -----------------------------------------------------------------------------------------------------
// Returns our desired size
- (int)desiredHeight
{
	int desiredHeight = [self totalHeight] + desiredHeightPadding;
	return ((desiredHeight > MINIMUM_HEIGHT || [self numberOfRows]) ? desiredHeight : MINIMUM_HEIGHT);
}

- (int)desiredWidth
{
	unsigned	row;
	unsigned	numberOfRows = [self numberOfRows];
	int			widestCell = 0;
	id			theDelegate = [self delegate];
	
	//Enumerate all rows, find the widest one
	for (row = 0; row < numberOfRows; row++) {
		id			item = [self itemAtRow:row];
		NSCell		*cell = ([self isExpandable:item] ? groupCell : contentCell);
	
		[theDelegate outlineView:self willDisplayCell:cell forTableColumn:nil item:item];
		int	width = [(AIListCell *)cell cellWidth];
		if (width > widestCell) widestCell = width;
	}
	return ((widestCell > minimumDesiredWidth) ? widestCell : minimumDesiredWidth);
}

- (void)setMinimumDesiredWidth:(int)inMinimumDesiredWidth
{
	minimumDesiredWidth = inMinimumDesiredWidth;
}

//Add padding to the desired height
- (void)setDesiredHeightPadding:(int)inPadding
{
	desiredHeightPadding = inPadding;
}

//Background image ---------------------------------------------------------------
//Draw our background image or color with transparency
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if ([self drawsBackground]) {
		//BG Color
		[[self backgroundColor] set];
		NSRectFill(clipRect);
		
		//Image
		NSScrollView	*enclosingScrollView = [self enclosingScrollView];
		if (backgroundImage && enclosingScrollView) {
			NSRect	visRect = [enclosingScrollView documentVisibleRect];
			NSSize	imageSize = [backgroundImage size];
			NSRect	imageRect = NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height);

			switch (backgroundStyle) {
				
				case AINormalBackground: {
					//Background image normal
					[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AIFillProportionatelyBackground: {
					//Background image proportional stretch
					
					//Make the width change by the same proportion as the height will change
					//visRect.size.width = imageSize.width * (visRect.size.height / imageSize.height);
					
					//Make the height change by the same proportion as the width will change
					visRect.size.height = imageSize.height * (visRect.size.width / imageSize.width);
					
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AIFillStretchBackground: {
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:backgroundFade];
					break;
				}
				case AITileBackground: {
					//Tiling
					NSPoint	currentOrigin;
					currentOrigin = visRect.origin;

					//We'll repeat this vertical process as long as necessary
					while (currentOrigin.y < (visRect.origin.y + visRect.size.height)) {
						//Reset the x axis to draw a series of images horizontally at this height
						currentOrigin.x = visRect.origin.x;
						
						//Draw as long as our origin is within the visible rect
						while (currentOrigin.x < (visRect.origin.x + visRect.size.width)) {
							NSRect drawingRect = NSMakeRect(currentOrigin.x, currentOrigin.y, imageSize.width, imageSize.height);
							if (NSIntersectsRect(drawingRect, clipRect)) {
								//Draw at the current x and y at least once with the original size
								[backgroundImage drawInRect:drawingRect
												   fromRect:imageRect
												  operation:NSCompositeSourceOver
												   fraction:backgroundFade];
							}

							//Shift right for the next iteration
							currentOrigin.x += imageSize.width;
						}
						
						//Shift down for the next series of horizontal draws
						currentOrigin.y += imageSize.height;
					}
					break;
				}
			}
		}
		
	} else {
		//If we aren't drawing a background, fill the rect with clearColor
		[[NSColor clearColor] set];
		NSRectFill(clipRect);
	}
}

#pragma mark Background

- (void)setBackgroundImage:(NSImage *)inImage
{
	if (backgroundImage != inImage) {
		[backgroundImage release];
		backgroundImage = [inImage retain];		
		[backgroundImage setFlipped:YES];
	}
	
	[(NSClipView *)[self superview] setCopiesOnScroll:(!backgroundImage)];
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundStyle:(AIBackgroundStyle)inBackgroundStyle
{
	backgroundStyle = inBackgroundStyle;
	[self setNeedsDisplay:YES];
}

//
- (void)setBackgroundOpacity:(float)opacity forWindowStyle:(AIContactListWindowStyle)inWindowStyle
{
	backgroundOpacity = opacity;

	//Reset all our opacity dependent values
	[_backgroundColorWithOpacity release]; _backgroundColorWithOpacity = nil;
	[_rowColorWithOpacity release]; _rowColorWithOpacity = nil;
	
	windowStyle = inWindowStyle;

	[self setNeedsDisplay:YES];

	/* This may be called repeatedly. We want to invalidate our shadow as our opacity changes, but we'll flicker
	 * if we do it immediately.
	 */
	[NSObject cancelPreviousPerformRequestsWithTarget:[self window]
											 selector:@selector(invalidateShadow)
											   object:nil];
	[[self window] performSelector:@selector(invalidateShadow)
	                    withObject:nil
	                    afterDelay:0.2];
}

- (void)setBackgroundFade:(float)fade
{
	backgroundFade = fade;
	[self setNeedsDisplay:YES];
}
- (float)backgroundFade
{
	//Factor in opacity
	return backgroundFade * backgroundOpacity;
}

//Background color (Opacity is added into the return automatically)
- (void)setBackgroundColor:(NSColor *)inColor
{
	if (backgroundColor != inColor) {
		[backgroundColor release];
		backgroundColor = [inColor retain];
		[_backgroundColorWithOpacity release];
		_backgroundColorWithOpacity = nil;
	}
	[self setNeedsDisplay:YES];
}
- (NSColor *)backgroundColor
{
	//Factor in opacity
	if (!_backgroundColorWithOpacity) { 
		float backgroundAlpha = ([backgroundColor alphaComponent] * backgroundOpacity);
		_backgroundColorWithOpacity = [[backgroundColor colorWithAlphaComponent:backgroundAlpha] retain];
		
		//Mockie and pillow lists always require a non-opaque window, other lists only require a non-opaque window when
		//the user has requested transparency.
		if (windowStyle == AIContactListWindowStyleGroupBubbles || windowStyle == AIContactListWindowStyleContactBubbles || windowStyle == AIContactListWindowStyleContactBubbles_Fitted) {
			[[self window] setOpaque:NO];
		} else {
			[[self window] setOpaque:(backgroundAlpha == 1.0f)];
		}
		
		//Turn our shadow drawing hack on if they're going to be visible through the transparency
		[self setUpdateShadowsWhileDrawing:(![[self window] isOpaque])];		
	}
	
	return _backgroundColorWithOpacity;
}

- (void)setDrawsBackground:(BOOL)inDraw
{
	[super setDrawsBackground:inDraw];

	//Mockie and pillow lists always require a non-opaque window, other lists only require a non-opaque window when
	//the user has requested transparency.
	if (windowStyle == AIContactListWindowStyleGroupBubbles || windowStyle == AIContactListWindowStyleContactBubbles || windowStyle == AIContactListWindowStyleContactBubbles_Fitted) {
		[[self window] setOpaque:NO];
	} else {
		//XXX Should we still use backgroundOpacity
		[[self window] setOpaque:(backgroundOpacity == 1.0)];
	}
}

- (void)setHighlightColor:(NSColor *)inColor
{
	if (highlightColor != inColor) {
		[self willChangeValueForKey:@"highlightColor"];
		[highlightColor release];
		highlightColor = [inColor retain];
		[self  didChangeValueForKey:@"highlightColor"];
	}
	[self setNeedsDisplay:YES];
}
- (NSColor *)highlightColor
{
	return highlightColor;
}

//Alternating row color (Opacity is added into the return automatically)
- (void)setAlternatingRowColor:(NSColor *)color
{
	if (rowColor != color) {
		[rowColor release];
		rowColor = [color retain];
		[_rowColorWithOpacity release];
		_rowColorWithOpacity = nil;
	}
	
	[self setNeedsDisplay:YES];
}

- (NSColor *)alternatingRowColor
{
	if (!_rowColorWithOpacity) {
		_rowColorWithOpacity = [[rowColor colorWithAlphaComponent:backgroundOpacity] retain];
	}
	
	return _rowColorWithOpacity;
}

// Don't consider list groups when highlighting
- (BOOL)shouldResetAlternating:(int)row
{
	return ([[self itemAtRow:row] isKindOfClass:[AIListGroup class]] && groupsHaveBackground);
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	
	[(NSClipView *)newSuperview setCopiesOnScroll:(!backgroundImage)];
}

- (void)drawRect:(NSRect)rect
{	
	[super drawRect:rect];

	/*	#################### Crappy Code ###################
	 *	Mac OS X 10.0 through 10.5.2 (and possibly beyond) do NOT invalidate the shadow
	 *	of a transparent window correctly, forcing us to do it manually each
	 *	time the window content is changed.  This is absolutely horrible for
	 *	performance, but the only way to avoid shadow ghosting :(
	 */
	if (updateShadowsWhileDrawing) [[self window] invalidateShadow];
}

- (AIGradient *)selectedControlGradient
{
	NSColor		*myHighlightColor = [self highlightColor];
	AIGradient 	*gradient = (myHighlightColor ?
							 [AIGradient gradientWithFirstColor:myHighlightColor
													secondColor:[myHighlightColor darkenAndAdjustSaturationBy:0.4] 
													  direction:AIVertical] :
							 [AIGradient selectedControlGradientWithDirection:AIVertical]);

	return gradient;
}

- (void)setUpdateShadowsWhileDrawing:(BOOL)update{
	updateShadowsWhileDrawing = update;
}

//Contact menu ---------------------------------------------------------------
//Return the selected object (to auto-configure the contact menu)
- (AIListObject *)listObject
{
    int selectedRow = [self selectedRow];

    if (selectedRow >= 0 && selectedRow < [self numberOfRows]) {
        return [self itemAtRow:selectedRow];
    } else {
        return nil;
    }
}

- (NSArray *)arrayOfListObjects
{
	return [self arrayOfSelectedItems];
}

- (int)indexOfFirstVisibleListContact
{
	unsigned int numberOfRows = [self numberOfRows];
	for (unsigned i = 0; i <numberOfRows ; i++) {
		if ([[self itemAtRow:i] isKindOfClass:[AIListContact class]]) {
			return i;
		}
	}
	
	return -1;
}

#pragma mark Group expanding
/*!
 * @brief Expand or collapses groups on mouse down
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int		row = [self rowAtPoint:viewPoint];
	id		item = [self itemAtRow:row];
	
	// Let super handle it if it's not a group, or the command key is down (dealing with selection)
	// Allow clickthroughs for triangle disclosure only.
	if (![item isKindOfClass:[AIListGroup class]] || [NSEvent cmdKey]) {
		[super mouseDown:theEvent];
		return;
	}
	
	//Wait for the next event
	NSEvent *nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
													untilDate:[NSDate distantFuture]
													   inMode:NSEventTrackingRunLoopMode
													  dequeue:NO];
	
	// Only expand/contract if they release the mouse. Otherwise pass on the goods.
	switch ([nextEvent type]) {
		case NSLeftMouseUp:
				if ([self isItemExpanded:item]) {
					[self collapseItem:item]; 
				} else {
					[self expandItem:item]; 
				}
				
				[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO]; 
			break;
		case NSLeftMouseDragged:
			[super mouseDown:theEvent];
			[super mouseDragged:nextEvent];
			break;
		default:
			[super mouseDown:theEvent];
			break;
	}	
}

#pragma mark Drag & Drop Drawing
/*!
 * @brief Called by NSOutineView to draw a drop highight
 *
 * Note: We are overriding a private method
 */
-(void)_drawDropHighlightOnRow:(int)rowIndex
{
	float widthOffset = 5.0;
	float heightOffset = 1.0;
	NSRect drawRect = [self rectOfRow:rowIndex];
	[NSGraphicsContext saveGraphicsState];
	//Ensure we don't draw outside our rect
	[[NSBezierPath bezierPathWithRect:drawRect] addClip];

	drawRect.size.width -= widthOffset;
	drawRect.origin.x += widthOffset/2.0;
	
	drawRect.size.height -= heightOffset;
	drawRect.origin.y += heightOffset/2.0;
	
	[self lockFocus];
	[[[NSColor blueColor] colorWithAlphaComponent:0.2] set];
	NSBezierPath	*filler = [NSBezierPath bezierPathWithRoundedRect:drawRect radius:4.0];
	[filler fill];
	
	[[[NSColor blueColor] colorWithAlphaComponent:0.8] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	NSBezierPath	*stroker = [NSBezierPath bezierPathWithRoundedRect:drawRect radius:4.0];
	[stroker stroke];
	[self unlockFocus];
	
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark Attach & Detach Groups

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{	
	unlockingGroup = NO;
	dragContent = nil;
	
	// Tell other windows that this is an internal drag & drop
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIListOutlineViewUnlockGroup"
														object:[NSNumber numberWithBool:unlockingGroup]];
	

	//From previous implementation - still needed?
	[[sender draggingDestinationWindow] makeKeyAndOrderFront:self];

	if ([[[sender draggingPasteboard] types] containsObject:@"AIListObjectUniqueIDs"]) {
		return NSDragOperationMove;
	} else {
		return [super draggingEntered:sender];
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	if (NSPointInRect([sender draggingLocation], [[[self window] contentView] frame])) {
		return;
	}
	
	unlockingGroup = YES;
	dragContent = [sender draggingPasteboard];

	// Tell other windows that something may be dropped in them
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIListOutlineViewUnlockGroup"
														object:[NSNumber numberWithBool:unlockingGroup]];
	[super draggingExited:sender];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return (NSDragOperationCopy | NSDragOperationMove | NSDragOperationPrivate);
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	NSArray			*dragUniqueIDs = nil;	// Items being dragged
	NSEnumerator	*idEnumerator = nil;	
	NSString		*uID = nil;				// Current group being dragged ID
	
	AIListGroup		*newContactList = nil;	// New contact list to be created
	AIListGroup		*currentGroup = nil;	// Current group being dragged
	
	//If nothing is being dragged, stop now.
	//How would this happen? -evands
	if (!dragContent)
		return;
	
	//The drag was canceled
	if (operation == NSDragOperationNone)
		return;

	id<AIInterfaceController>		interfaceController = [[AIObject sharedAdiumInstance] interfaceController];
	id<AIContactController>			contactController = [[AIObject sharedAdiumInstance] contactController];
	
	
	// Group being unlocked from current location
	if (unlockingGroup && [[dragContent types] containsObject:@"AIListObjectUniqueIDs"]) {
		dragUniqueIDs = [dragContent propertyListForType:@"AIListObjectUniqueIDs"];
		idEnumerator = [dragUniqueIDs objectEnumerator];

		while ((uID = [idEnumerator nextObject])) {
			currentGroup = (AIListGroup  *)[contactController existingListObjectWithUniqueID:uID];
			
			if ([currentGroup isKindOfClass:[AIListGroup class]]) {
				// If root of contact list was not yet created, create it now
				if (!newContactList)
					newContactList = [contactController createDetachedContactList];

				
				[self moveGroup:currentGroup to:newContactList];
			}	
		}
		
		if (newContactList) {
			// Update the new contact list
			[[NSNotificationCenter defaultCenter] postNotificationName:@"Contact_ListChanged"
																object:newContactList
															  userInfo:nil];
			
			// Detach the contact list to a window and set its origin
			[[[interfaceController detachContactList:newContactList] window] setFrameTopLeftPoint:aPoint];
		}
	}
	
	dragContent = nil;
	
	[[self dataSource] outlineView:self draggedImage:anImage endedAt:aPoint operation:operation]; 
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation 
		   offset:(NSSize)initialOffset event:(NSEvent *)event 
	   pasteboard:(NSPasteboard *)pboard source:(id)sourceObj 
		slideBack:(BOOL)slideFlag
{ 
	// In case drag&drop ends while we are still drawing
	[pboard retain];
	
	// If we are dragging a group item then don't slide back
	if([[pboard types] containsObject:@"AIListObjectUniqueIDs"]){
		NSArray *objects = [pboard propertyListForType:@"AIListObjectUniqueIDs"];
		AIListObject *item = [[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:[objects objectAtIndex:0]];
		if([item isKindOfClass:[AIListGroup class]])
			slideFlag = NO;
	}
		
	[super dragImage:anImage
				  at:viewLocation
			  offset:initialOffset
			   event:event
		  pasteboard:pboard
			  source:sourceObj
		   slideBack:slideFlag];
	
	[pboard release];
}

- (void)setUnlockGroup:(NSNotification *)notification
{
	unlockingGroup = [[notification object] boolValue];
}

/*!
 * @brief Moves group from one contact list to another
 */
- (BOOL)moveGroup:(AIListGroup *)group to:(AIListObject<AIContainingObject> *)list
{
	if(![group moveGroupFrom:[[self dataSource] contactList] to:list])
		return NO;
	
	// Update contact list content and size
	[[self dataSource] setContactListRoot:[[self dataSource] contactList]];
	[[self dataSource] contactListDesiredSizeChanged];
	
	return YES;
}

- (IBAction)copy:(id)sender
{
	id dataSource = [self dataSource];

	if (dataSource) {
		NSIndexSet *selection = [self selectedRowIndexes];

		NSMutableArray *items = [NSMutableArray arrayWithCapacity:[selection count]];
		for (unsigned idx = [selection firstIndex]; idx <= [selection lastIndex]; idx = [selection indexGreaterThanIndex:idx]) {
			[items addObject:[self itemAtRow:idx]];
		}

		[dataSource outlineView:self
	                 writeItems:items
	               toPasteboard:[NSPasteboard generalPasteboard]];
	}
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if ([anItem action] == @selector(copy:))
		return [self numberOfSelectedRows] > 0;
	else
		return [super validateUserInterfaceItem:anItem];
}

/*!
 * @brief Should we perform type select next/previous on find?
 *
 * @return YES to switch between type-select results. NO to to switch within the responder chain.
 */
- (BOOL)tabPerformsTypeSelectFind
{
	return YES;
}

@end

