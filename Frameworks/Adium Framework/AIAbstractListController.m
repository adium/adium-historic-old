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

#import "AIAbstractListController.h"
#import "AIContactController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AIListCell.h"
#import "AIListContactBubbleCell.h"
#import "AIListContactBubbleToFitCell.h"
#import "AIListContactCell.h"
#import "AIListContactMockieCell.h"
#import "AIListGroup.h"
#import "AIListGroupBubbleCell.h"
#import "AIListGroupBubbleToFitCell.h"
#import "AIListGroupCell.h"
#import "AIListGroupMockieCell.h"
#import "AIListObject.h"
#import "AIListOutlineView.h"
#import "AIMenuController.h"
#import "AIMetaContact.h"
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <Adium/KFTypeSelectTableView.h>

#define CONTENT_FONT_IF_FONT_NOT_FOUND	[NSFont systemFontOfSize:10]
#define STATUS_FONT_IF_FONT_NOT_FOUND	[NSFont systemFontOfSize:10]
#define GROUP_FONT_IF_FONT_NOT_FOUND	[NSFont systemFontOfSize:10]

@interface AIAbstractListController (PRIVATE)
- (LIST_POSITION)pillowsFittedIconPositionForIconPosition:(LIST_POSITION)iconPosition contentCellAlignment:(NSTextAlignment)contentCellAlignment;
@end

@implementation AIAbstractListController
/*
 * @brief Initialize
 *
 * Designated initializer for AIAbstractListController
 */
- (id)initWithContactListView:(AIListOutlineView *)inContactListView inScrollView:(AIAutoScrollView *)inScrollView_contactList delegate:(id<AIListControllerDelegate>)inDelegate
{
	if ((self = [super init]))
	{
		contactListView = [inContactListView retain];
		scrollView_contactList = [inScrollView_contactList retain];
		delegate = inDelegate;

		hideRoot = YES;
		dragItems = nil;
		showTooltips = YES;
		showTooltipsInBackground = NO;
		backgroundOpacity = 1.0;

		[self configureViewsAndTooltips];
		
		//Watch for drags ending so we can clear any cached drag data
		[[adium notificationCenter] addObserver:self
									   selector:@selector(listControllerDragEnded:)
										   name:@"AIListControllerDragEnded"
										 object:nil];
		
		[[adium notificationCenter] addObserver:self
									   selector:@selector(listObjectAttributesChanged:)
										   name:ListObject_AttributesChanged
										 object:nil];
	}

	return self;
}

/*
 * @brief Delegate
 */
- (id)delegate
{
	return delegate;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[contactList release];
	[contactListView setDelegate:nil];
	
	[contactListView release]; contactListView = nil;
	[scrollView_contactList release]; scrollView_contactList = nil;
	
	if (tooltipTracker) {
		[tooltipTracker setDelegate:nil];
		[tooltipTracker release]; tooltipTracker = nil;
	}

	[groupCell release];
	[contentCell release];
	
	[[adium notificationCenter] removeObserver:self]; 

    [super dealloc];
}

/*
 * @brief If the contact list will be removed but the window won't go away, call this before releasing.
 *
 * Note that for this to be useful for preventing Cocoa tracking rect oddity, it must be called
 * while contactListView is still within its window.  The reason we have to do this is that if the view is removed
 * from the window but this contorller is released in the process, the tracking rect won't be removed from the window
 * when the tooltipTracker removes it from the view.  After that, a simple mouseEntered: or mouseExited: event will
 * send that message on to the deallocated AISmoothTooltipTracker instance.  Braaains.
 */
- (void)contactListWillBeRemoved
{
	if (tooltipTracker) {
		[tooltipTracker setDelegate:nil];
		[tooltipTracker release]; tooltipTracker = nil;
	}	
}

//Setup the window after it has loaded
- (void)configureViewsAndTooltips
{
	//Configure the contact list view
	tooltipTracker = [[AISmoothTooltipTracker smoothTooltipTrackerForView:scrollView_contactList
															 withDelegate:self] retain];

	[[[contactListView tableColumns] objectAtIndex:0] setDataCell:[[[AIListContactCell alloc] init] autorelease]];
	
	//Targeting
    [contactListView setTarget:self];
    [contactListView setDelegate:self];	
	[contactListView setDataSource:self];	
	[contactListView setDoubleAction:@selector(performDefaultActionOnSelectedItem:)];
	
	//We handle our own intercell spacing, so override the default (3.0, 2.0) to be (0.0, 0.0) instead.
	[contactListView setIntercellSpacing:NSZeroSize];
	
	[scrollView_contactList setDrawsBackground:NO];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];

	//Dragging
	[contactListView registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs", NSFilenamesPboardType, NSURLPboardType, NSStringPboardType, nil]];
}

- (void)setContactListRoot:(ESObjectWithStatus<AIContainingObject> *)newContactListRoot
{
	if (contactList != newContactListRoot) {
		[contactList release]; contactList = [newContactListRoot retain];
	}

	[contactListView reloadData];
}

- (ESObjectWithStatus <AIContainingObject> *)contactListRoot
{
	return contactList;
}

- (void)setHideRoot:(BOOL)inHideRoot
{
	hideRoot = inHideRoot;
	[contactListView reloadData];
}

//Double click in outline view
- (IBAction)performDefaultActionOnSelectedItem:(NSOutlineView *)sender
{
    AIListObject	*selectedObject = [sender itemAtRow:[sender selectedRow]];
	[delegate performDefaultActionOnSelectedObject:selectedObject sender:sender];
}

- (void)reloadData
{
	[contactListView reloadData];
}

//Preferences ---------------------------------------------
#pragma mark Preferences

- (LIST_WINDOW_STYLE)windowStyle
{
	return WINDOW_STYLE_STANDARD;
}

- (void)updateLayoutFromPrefDict:(NSDictionary *)prefDict andThemeFromPrefDict:(NSDictionary *)themeDict
{
	LIST_WINDOW_STYLE	windowStyle = [self windowStyle];
	NSTextAlignment		contentCellAlignment;
	BOOL				pillowsOrPillowsFittedWindowStyle;
	
	//Cells
	[groupCell release];
	[contentCell release];

	switch (windowStyle) {
		case WINDOW_STYLE_STANDARD:
		case WINDOW_STYLE_BORDERLESS:
			groupCell = [[AIListGroupCell alloc] init];
			contentCell = [[AIListContactCell alloc] init];
		break;
		case WINDOW_STYLE_MOCKIE:
			groupCell = [[AIListGroupMockieCell alloc] init];
			contentCell = [[AIListContactMockieCell alloc] init];
		break;
		case WINDOW_STYLE_PILLOWS:
			groupCell = [[AIListGroupBubbleCell alloc] init];
			contentCell = [[AIListContactBubbleCell alloc] init];
		break;
		case WINDOW_STYLE_PILLOWS_FITTED:
			groupCell = [[AIListGroupBubbleToFitCell alloc] init];
			contentCell = [[AIListContactBubbleToFitCell alloc] init];
		break;
	}
	[contactListView setGroupCell:groupCell];
	[contactListView setContentCell:contentCell];
	
	//Re-apply opacity settings for the new cells
	[self setBackgroundOpacity:backgroundOpacity];
	
	//"Preferences" determined by the subclass of AIAbstractListController
	[contentCell setUseAliasesAsRequested:[self useAliasesInContactListAsRequested]];
	[contentCell setShouldUseContactTextColors:[self shouldUseContactTextColors]];
		
	//Alignment
	contentCellAlignment = [[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue];
	[contentCell setTextAlignment:contentCellAlignment];
	[groupCell setTextAlignment:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];
	[contentCell setUserIconSize:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];

	if (windowStyle != WINDOW_STYLE_PILLOWS_FITTED) {
		[contentCell setUserIconVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
		[contentCell setExtendedStatusVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
		[contentCell setStatusIconsVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
		[contentCell setServiceIconsVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];

		[contentCell setUserIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue]];
		[contentCell setStatusIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue]];
		[contentCell setServiceIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue]];
		[contentCell setExtendedStatusIsBelowName:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] boolValue]];		
	} else {
		//Fitted pillows + centered text = no icons
		BOOL allowIcons = (contentCellAlignment != NSCenterTextAlignment);
		
		[contentCell setUserIconVisible:(allowIcons ? [[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue] : NO)];
		[contentCell setStatusIconsVisible:(allowIcons ? [[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue] : NO)];
		[contentCell setServiceIconsVisible:(allowIcons ? [[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue] : NO)];

		[contentCell setExtendedStatusVisible:NO /*(allowIcons ? [[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue] : NO)*/];

		if (allowIcons) {
			LIST_POSITION iconPosition;
			
			iconPosition = [[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue];
			iconPosition = [self pillowsFittedIconPositionForIconPosition:iconPosition
													 contentCellAlignment:contentCellAlignment];
			[contentCell setUserIconPosition:iconPosition];
			
			iconPosition = [[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue];
			iconPosition = [self pillowsFittedIconPositionForIconPosition:iconPosition
													 contentCellAlignment:contentCellAlignment];
			[contentCell setStatusIconPosition:iconPosition];
			
			iconPosition = [[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue];
			iconPosition = [self pillowsFittedIconPositionForIconPosition:iconPosition
													 contentCellAlignment:contentCellAlignment];
			[contentCell setServiceIconPosition:iconPosition];
			
			//Force extended status below the name (?)
			[contentCell setExtendedStatusIsBelowName:YES];
		}
	}
	
	//Fonts
	NSFont	*theFont;
	
	theFont = [[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_FONT] representedFont];
	[contentCell setFont:(theFont ? theFont : CONTENT_FONT_IF_FONT_NOT_FOUND)];
	
	theFont = [[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_FONT] representedFont];
	[contentCell setStatusFont:(theFont ? theFont : STATUS_FONT_IF_FONT_NOT_FOUND)];
	
	theFont = [[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_FONT] representedFont];
	[groupCell setFont:(theFont ? theFont : GROUP_FONT_IF_FONT_NOT_FOUND)];

	//Standard special cases.  Add an extra line of padding to the bottom of the standard window.
	if (windowStyle == WINDOW_STYLE_STANDARD) {
		[contactListView setDesiredHeightPadding:3];   //1 pixel border at the top and bottom + extra line at bottom
	} else {
		[contactListView setDesiredHeightPadding:2];   //Accounts for the 1 pixel border at the top and bottom
	}
	
	//Bubbles special cases
	pillowsOrPillowsFittedWindowStyle = (windowStyle == WINDOW_STYLE_PILLOWS || windowStyle == WINDOW_STYLE_PILLOWS_FITTED);
	if (pillowsOrPillowsFittedWindowStyle) {
		//Treat the padding as spacing
		[contentCell setSplitVerticalSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		[contentCell setLeftSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
		[contentCell setRightSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
		[groupCell setSplitVerticalSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
	} else {
		[contentCell setSplitVerticalPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		[contentCell setLeftPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
		[contentCell setRightPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
	}
	
	//Mockie special cases.  For all other layouts we use fixed group spacing
	if (windowStyle == WINDOW_STYLE_MOCKIE) {
		[groupCell setTopSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] intValue]];
	} else if (windowStyle == WINDOW_STYLE_STANDARD) {
		//Force some spacing and draw a bordeer around our groups (This doesn't look good in borderless)
		[groupCell setTopSpacing:1];
		[groupCell setLeftSpacing:1];
		[groupCell setRightSpacing:1];
		[groupCell setDrawsGradientEdges:YES];
	}
	
	//Disable square row highlighting for bubble lists - the bubble cells handle this on their own
	if (windowStyle == WINDOW_STYLE_MOCKIE ||
	   pillowsOrPillowsFittedWindowStyle) {
		[contactListView setDrawsSelectedRowHighlight:NO];
	}
	
	//Pillows special cases
	if (pillowsOrPillowsFittedWindowStyle) {
		BOOL	outlineBubble = [[prefDict objectForKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE] boolValue];
		int		outlineBubbleLineWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_OUTLINE_BUBBLE_WIDTH] intValue];

		[(AIListContactBubbleCell *)contentCell setOutlineBubble:outlineBubble];
		[(AIListContactBubbleCell *)contentCell setOutlineBubbleLineWidth:outlineBubbleLineWidth];
		[(AIListContactBubbleCell *)contentCell setDrawWithGradient:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_BUBBLE_GRADIENT] boolValue]];		

		[(AIListGroupBubbleCell *)groupCell setOutlineBubble:outlineBubble];
		[(AIListGroupBubbleCell *)groupCell setOutlineBubbleLineWidth:outlineBubbleLineWidth];
		[(AIListGroupBubbleCell *)groupCell setHideBubble:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_HIDE_BUBBLE] boolValue]];
	}
	
	//Background
	[contactListView setDrawsAlternatingRows:[[themeDict objectForKey:KEY_LIST_THEME_GRID_ENABLED] boolValue]];
	[contactListView setBackgroundFade:[[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_FADE] floatValue]];
	[contactListView setBackgroundColor:[[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_COLOR] representedColor]];
	[contactListView setAlternatingRowColor:[[themeDict objectForKey:KEY_LIST_THEME_GRID_COLOR] representedColor]];

	//Highlight
	NSNumber *highlightEnabledNum = [themeDict objectForKey:KEY_LIST_THEME_HIGHLIGHT_ENABLED];
	NSColor *highlight = nil;
	if (highlightEnabledNum && [highlightEnabledNum boolValue]) {
		highlight = [[themeDict objectForKey:KEY_LIST_THEME_HIGHLIGHT_COLOR] representedColor];
	}
	[contactListView setHighlightColor:highlight];

	//Disable background image if we're in mockie or pillows
	[contactListView setDrawsBackground:(windowStyle != WINDOW_STYLE_MOCKIE &&
										 !(pillowsOrPillowsFittedWindowStyle))];
	[contactListView setBackgroundStyle:[[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_STYLE] intValue]];

	//Desired Size determination.  For non-standard (borderless) styles, ignore the minimum width.
	[contactListView setIgnoreMinimumWidth:(windowStyle != WINDOW_STYLE_STANDARD)];

	//Theme related cell preferences
	//We must re-apply these because we've created new cells
	[self updateCellRelatedThemePreferencesFromDict:themeDict];
	
	//Outline View
	[contactListView setGroupCell:groupCell];
	[contactListView setContentCell:contentCell];
	[contactListView setNeedsDisplay:YES];
	
	[self contactListDesiredSizeChanged];
}

//Background opacity is set independently from layout
- (void)setBackgroundOpacity:(float)opacity
{
	backgroundOpacity = opacity;

	//Update our view and content cell for the new opacity.  Group cells are kept opaque.
	[contentCell setBackgroundOpacity:backgroundOpacity];
	[contactListView setBackgroundOpacity:backgroundOpacity forWindowStyle:[self windowStyle]];	
}

//Adjust an iconPosition to be valid for a fitted aligned pillow; 
//aligned left means the iconPosition must be on the left, and aligned right means on the right
- (LIST_POSITION)pillowsFittedIconPositionForIconPosition:(LIST_POSITION)iconPosition contentCellAlignment:(NSTextAlignment)contentCellAlignment
{
	if ((contentCellAlignment == NSLeftTextAlignment) && ((iconPosition == LIST_POSITION_RIGHT) ||
														  (iconPosition == LIST_POSITION_FAR_RIGHT))) {
		iconPosition = LIST_POSITION_LEFT;
		
	} else if ((contentCellAlignment == NSRightTextAlignment) && ((iconPosition == LIST_POSITION_LEFT) ||
																 (iconPosition == LIST_POSITION_FAR_LEFT))) {
		iconPosition = LIST_POSITION_RIGHT;
	}
	
	return iconPosition;
}

- (void)updateCellRelatedThemePreferencesFromDict:(NSDictionary *)prefDict
{
	[groupCell setBackgroundColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND] representedColor]
					gradientColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT] representedColor]];

	if ([[prefDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW] boolValue]) {
		[groupCell setShadowColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR] representedColor]];
	}
	
	[groupCell setDrawsBackground:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_GRADIENT] boolValue]];
	[groupCell setTextColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR] representedColor]];

	[contentCell setBackgroundColorIsStatus:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_AS_STATUS] boolValue]];
	[contentCell setBackgroundColorIsEvents:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_AS_EVENTS] boolValue]];
	[contentCell setStatusColor:[[prefDict objectForKey:KEY_LIST_THEME_CONTACT_STATUS_COLOR] representedColor]];
}

#pragma mark Updating the display
/*!
 * @brief List object attributes changed
 *
 * Redisplay the object in question
 */
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
	
	//Redraw the modified object (or the whole list, if object is nil)
	[contactListView redisplayItem:object];	
}


//Outline View data source ---------------------------------------------------------------------------------------------
#pragma mark Outline View data source
//
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if (item == nil) {
		if (hideRoot) {
			return (index >= 0 && index < [contactList containedObjectsCount]) ? [contactList objectAtIndex:index] : nil;
		} else {
			return contactList;
		}
    } else {
        return (index >= 0 && index < [item containedObjectsCount]) ? [item objectAtIndex:index] : nil;
    }
}

//
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
		if (hideRoot) {
			return [contactList visibleCount];
		} else {
			return 1;
		}
    } else {
        return [item visibleCount];
    }
}

/*!
 * @brief Configure the cell for the proper listObject before drawing
 *
 * @param outlineView The AIListOutlineView which is drawing
 * @param cell An AIListCell within the AIListOutlineView
 * @param tableColumn (Ignored)
 * @param item The AIListObject which well be drawn by the cell
 */
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([outlineView isKindOfClass:[AIListOutlineView class]]) {
		[(AIListCell *)cell setListObject:item];
		[(AIListCell *)cell setControlView:(AIListOutlineView *)outlineView];
	}
}

//
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return @"";
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[AIListGroup class]];
}

//
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    [item setExpanded:state];
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return [item isExpanded];
}

/*!
 * @brief Return the contextual menu for a passed list object
 */
- (NSMenu *)contextualMenuForListObject:(AIListObject *)listObject
{
	BOOL			isGroup = [listObject isKindOfClass:[AIListGroup class]];
	NSArray			*locationsArray = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:(isGroup ? Context_Group_Manage : Context_Contact_Manage)],
		[NSNumber numberWithInt:Context_Contact_Action],
		[NSNumber numberWithInt:Context_Contact_ListAction],
		[NSNumber numberWithInt:Context_Contact_NegativeAction],
		[NSNumber numberWithInt:Context_Contact_Additions], nil];

    return [[adium menuController] contextualMenuWithLocations:locationsArray
												 forListObject:listObject];
}

//
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent
{
    NSPoint	location;
    int		row;
    id		item;
	
    //Get the clicked item
    location = [outlineView convertPoint:[theEvent locationInWindow] fromView:[[outlineView window] contentView]];
    row = [outlineView rowAtPoint:location];
    item = [outlineView itemAtRow:row];
	
    //Select the clicked row and bring the window forward
    [outlineView selectRow:row byExtendingSelection:NO];
    [[outlineView window] makeKeyAndOrderFront:nil];
	
    //Hide any open tooltip
    [self hideTooltip];
	
    //Return the context menu
	AIListObject	*listObject = (AIListObject *)[outlineView firstSelectedItem];

	return [self contextualMenuForListObject:listObject];
}

#pragma mark Finder-style searching

/*!
 * @brief Configure the type select table view for wrapping
 */
- (void)configureTypeSelectTableView:(KFTypeSelectTableView *)tableView
{
    [tableView setSearchWraps:YES]; 
}

/*!
 * @brief Return the string value used for type selection
 */
- (NSString *)typeSelectTableView:(KFTypeSelectTableView *)tableView stringValueForTableColumn:(NSTableColumn *)col row:(int)row
{
    NSString *stringValue = @"";
    
    if ((id)tableView == (id)contactListView)
    {
        id item = [contactListView itemAtRow:row];
        
        AIListCell *cell;
        if ([item isKindOfClass:[AIListGroup class]])
            cell = groupCell;
        else
            cell = contentCell;
 
        [self outlineView:contactListView 
          willDisplayCell:cell
           forTableColumn:col
                     item:item];
        
        stringValue = [cell labelString];
    }
    
    return stringValue;
}

#pragma mark Drag and drop
/*!
 * @brief Initiate drag and drop by writing items to the pasteboard
 *
 * We provide @"Private" for AIListObject, indicating we are using the private dragItems instance variable.
 * We promise @"AIListObjectUniqueIDs" which will be generated as needed as an array of uniqueObjectIDs corresponding to
 * the drag items array.
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
	//Kill any selections
	[outlineView deselectAll:nil];
	
	//Begin the drag
	if (dragItems != items) {
		[dragItems release];
		dragItems = [items retain];
	}
	
	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",@"AIListObjectUniqueIDs",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	if (dragItems) {
		[dragItems release]; dragItems = nil;
	}
	
	return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	//Post a notification that the drag ended so any other list controllers which have cached the drag can clear it
	[[adium notificationCenter] postNotificationName:@"AIListControllerDragEnded"
											  object:nil];
}

- (void)listControllerDragEnded:(NSNotification *)notification
{
	if (dragItems) {
		[dragItems release]; dragItems = nil;
	}	
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	//Provide an array of internalObjectIDs which can be used to reference all the dragged contacts
	if ([type isEqualToString:@"AIListObjectUniqueIDs"]) {
		
		if (dragItems) {
			NSMutableArray	*dragItemsArray = [NSMutableArray array];
			NSEnumerator	*enumerator = [dragItems objectEnumerator];
			AIListObject	*listObject;
			
			while ((listObject = [enumerator nextObject])) {
				[dragItemsArray addObject:[listObject internalObjectID]];
			}
			
			[sender setPropertyList:dragItemsArray forType:@"AIListObjectUniqueIDs"];
		}
	}
}

//Tooltip --------------------------------------------------------------------------------------------------------------
#pragma mark Tooltip
//Show tooltip
- (void)showTooltipAtPoint:(NSPoint)screenPoint
{
	AIListObject	*hoveredObject = [self contactListItemAtScreenPoint:screenPoint];
	
	if ([hoveredObject isKindOfClass:[AIListContact class]]) {
		[[adium interfaceController] showTooltipForListObject:hoveredObject
												atScreenPoint:screenPoint
													 onWindow:[contactListView window]];
	} else {
		[self hideTooltip];
	}
}

- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint
{
	AIListObject	*listObject = nil;

	if (showTooltips && (showTooltipsInBackground || [NSApp isActive])) {
		NSRect		contactListFrame = [contactListView frame];
		NSPoint		viewPoint = [contactListView convertPoint:[[contactListView window] convertScreenToBase:screenPoint]
													 fromView:nil];
		
		//Be sure that screen points outside our view return nil, since no contact is being hovered.
		if (viewPoint.x > NSMinX(contactListFrame) && viewPoint.x < NSMaxX(contactListFrame)) {
			listObject = [contactListView itemAtRow:[contactListView rowAtPoint:viewPoint]];
		}
	}
	
	return listObject;
}

//Hide tooltip
- (void)hideTooltip
{
	[[adium interfaceController] showTooltipForListObject:nil atScreenPoint:NSMakePoint(0,0) onWindow:nil];
}


//----------------
//For Subclasses
- (void)contactListDesiredSizeChanged {};
- (void)updateTransparency {};
- (BOOL)useAliasesInContactListAsRequested{
	return YES;
}
- (BOOL)shouldUseContactTextColors{
	return YES;
}

/*!
 * @brief Show tooltips?
 */
- (void)setShowTooltips:(BOOL)inShowTooltips
{
	showTooltips = inShowTooltips;	
}

/*!
 * @brief Show tooltips when Adium is in the background?
 *
 * Only relevant if showTooltips is set to YES.
 */
- (void)setShowTooltipsInBackground:(BOOL)inShowTooltipsInBackground
{
	showTooltipsInBackground = inShowTooltipsInBackground;
}

@end
