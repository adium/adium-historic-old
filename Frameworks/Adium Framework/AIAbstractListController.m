//
//  AIAbstractListController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/21/04.
//

#import "AIAbstractListController.h"

#import "AIListCell.h"
#import "AIListOutlineView.h"
#import "AIListGroupGradientCell.h"
#import "AIListContactCell.h"
#import "AIListContactBubbleCell.h"
#import "AIListGroupMockieCell.h"
#import "AIListContactMockieCell.h"
#import "AIListContactBubbleToFitCell.h"
#import "AIListGroupBubbleCell.h"
#import "AIListGroupBubbleToFitCell.h"

#define CONTENT_FONT_IF_FONT_NOT_FOUND	[NSFont systemFontOfSize:10]
#define STATUS_FONT_IF_FONT_NOT_FOUND	[NSFont systemFontOfSize:10]
#define GROUP_FONT_IF_FONT_NOT_FOUND	[NSFont systemFontOfSize:10]

@interface AIAbstractListController (PRIVATE)
- (void)configureViewsAndTooltips;
- (BOOL)shouldShowTooltips;
@end

@implementation AIAbstractListController

- (id)initWithContactListView:(AIListOutlineView *)inContactListView inScrollView:(AIAutoScrollView *)inScrollView_contactList delegate:(id<AIListControllerDelegate>)inDelegate
{
	[super init];
	
	contactListView = [inContactListView retain];
	scrollView_contactList = [inScrollView_contactList retain];
	delegate = inDelegate;
	
	hideRoot = YES;
	dragItems = nil;
	
	[self configureViewsAndTooltips];
	
	return(self);
}

- (id)delegate
{
	return(delegate);
}

//Dealloc
- (void)dealloc
{
	[contactListView setDelegate:nil];
	
	[contactListView release]; contactListView = nil;
	[scrollView_contactList release]; scrollView_contactList = nil;
	
	if (tooltipTracker){
		[tooltipTracker setDelegate:nil];
		[tooltipTracker release]; tooltipTracker = nil;
	}

	[groupCell release];
	[contentCell release];
	
    [super dealloc];
}

//Setup the window after it has loaded
- (void)configureViewsAndTooltips
{
	//Configure the contact list view
	if ([self shouldShowTooltips]){
		tooltipTracker = [[AISmoothTooltipTracker smoothTooltipTrackerForView:scrollView_contactList withDelegate:self] retain];
	}else{
		tooltipTracker = nil;
	}
	
	[[[contactListView tableColumns] objectAtIndex:0] setDataCell:[[AIListContactCell alloc] init]];
	
	//Targeting
    [contactListView setTarget:self];
    [contactListView setDelegate:self];	
	[contactListView setDataSource:self];	
	[contactListView setDoubleAction:@selector(performDefaultActionOnSelectedItem:)];
	
	[scrollView_contactList setDrawsBackground:NO];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];

	//Dragging
	[contactListView registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];
}

- (void)setContactListRoot:(ESObjectWithStatus <AIContainingObject> *)newContactListRoot
{
	[contactList release]; contactList = [newContactListRoot retain];
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
- (IBAction)performDefaultActionOnSelectedItem:(id)sender
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
- (void)updateLayoutFromPrefDict:(NSDictionary *)prefDict andThemeFromPrefDict:(NSDictionary *)themeDict
{
	LIST_WINDOW_STYLE	windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
	float				backgroundAlpha	= [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue];
	BOOL				groupGradient = [[themeDict objectForKey:KEY_LIST_THEME_GROUP_GRADIENT] boolValue];
	
	//Cells
	[groupCell release];
	[contentCell release];

	switch(windowStyle){
		case WINDOW_STYLE_STANDARD:
		case WINDOW_STYLE_BORDERLESS:
			groupCell = (groupGradient ? [[AIListGroupGradientCell alloc] init] : [[AIListGroupCell alloc] init]);
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

	//"Preferences" determined by the subclass of AIAbstractListController
	[contentCell setUseAliasesAsRequested:[self useAliasesInContactListAsRequested]];
	[contentCell setShouldUseContactTextColors:[self shouldUseContactTextColors]];
		
	//Alignment
	[contentCell setTextAlignment:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]];
	[groupCell setTextAlignment:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];
	[contentCell setUserIconSize:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];
	
	[contentCell setUserIconVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
	[contentCell setExtendedStatusVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
	[contentCell setStatusIconsVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
	[contentCell setServiceIconsVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];

	[contentCell setUserIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue]];
	[contentCell setStatusIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue]];
	[contentCell setServiceIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue]];
	[contentCell setExtendedStatusIsBelowName:[[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] boolValue]];
	
	//Fonts
	NSFont	*theFont;
	
	theFont = [[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_FONT] representedFont];
	[contentCell setFont:(theFont ? theFont : CONTENT_FONT_IF_FONT_NOT_FOUND)];
	
	theFont = [[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_FONT] representedFont];
	[contentCell setStatusFont:(theFont ? theFont : STATUS_FONT_IF_FONT_NOT_FOUND)];

	theFont = [[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_FONT] representedFont];
	[groupCell setFont:(theFont ? theFont : GROUP_FONT_IF_FONT_NOT_FOUND)];
	
	//Bubbles special cases
	if(windowStyle == WINDOW_STYLE_PILLOWS || windowStyle == WINDOW_STYLE_PILLOWS_FITTED){
		//Treat the padding as spacing
		[contentCell setSplitVerticalSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		[contentCell setLeftSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
		[contentCell setRightSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
		[groupCell setSplitVerticalSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		
		//Disable square row highlighting, our bubble cells handle this on their own
		[contactListView setDrawsSelectedRowHighlight:NO];

	}else{
		[contentCell setSplitVerticalPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		[contentCell setLeftPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
		[contentCell setRightPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
	}
	
	//Mockie special cases
	if(windowStyle == WINDOW_STYLE_MOCKIE){
		[groupCell setTopSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] intValue]];
	}
	
	//Background
	//Disable background image if we're in mockie or pillows
	if([contentCell respondsToSelector:@selector(setBackgroundOpacity:)]){
		[contentCell setBackgroundOpacity:backgroundAlpha];
	}
	if([contactListView respondsToSelector:@selector(setDrawsBackground:)]){
		[contactListView setDrawsBackground:(windowStyle != WINDOW_STYLE_MOCKIE &&
											 windowStyle != WINDOW_STYLE_PILLOWS &&
											 windowStyle != WINDOW_STYLE_PILLOWS_FITTED)];
	}
	
	//Shadow
	[[contactListView window] setHasShadow:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_SHADOWED] boolValue]];
	
	//Theme related cell preferences
	//We must re-apply these because we've created new cells
	[self updateCellRelatedThemePreferencesFromDict:themeDict];
	
	//Outline View
	[contactListView setGroupCell:groupCell];
	[contactListView setContentCell:contentCell];
	[contactListView setNeedsDisplay:YES];
	
	[self contactListDesiredSizeChanged:nil];
}

- (void)updateTransparencyFromLayoutDict:(NSDictionary *)layoutDict themeDict:(NSDictionary *)themeDict
{
	float			backgroundAlpha	= [[layoutDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue];
	int				windowStyle = [[layoutDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
	
	[contactListView setBackgroundFade:([[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_FADE] floatValue] * backgroundAlpha)];
	[contactListView setBackgroundColor:[[[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_COLOR] representedColor] colorWithAlphaComponent:backgroundAlpha]];
	[contactListView setAlternatingRowColor:[[[themeDict objectForKey:KEY_LIST_THEME_GRID_COLOR] representedColor] colorWithAlphaComponent:backgroundAlpha]];
	
	//Mockie and pillow special cases
	if(windowStyle == WINDOW_STYLE_MOCKIE || windowStyle == WINDOW_STYLE_PILLOWS || windowStyle == WINDOW_STYLE_PILLOWS_FITTED){
		backgroundAlpha = 0.0;
		[contactListView setDrawsAlternatingRows:NO];
	}else{
		[contactListView setDrawsAlternatingRows:(backgroundAlpha == 0.0 ? NO : [[themeDict objectForKey:KEY_LIST_THEME_GRID_ENABLED] boolValue])];
	}
	
	//Transparency.  Bye bye CPU cycles, I'll miss you!
	[[contactListView window] setOpaque:(backgroundAlpha == 1.0)];
	if ([contactListView respondsToSelector:@selector(setUpdateShadowsWhileDrawing:)]){
		[contactListView setUpdateShadowsWhileDrawing:(backgroundAlpha < 0.8)];
	}
}

- (void)updateCellRelatedThemePreferencesFromDict:(NSDictionary *)prefDict
{
	if([groupCell isKindOfClass:[AIListGroupGradientCell class]]){
		[(AIListGroupGradientCell *)groupCell setBackgroundColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND] representedColor]
												   gradientColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT] representedColor]];

		[(AIListGroupGradientCell *)groupCell setShadowColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR] representedColor]];
	}

	[groupCell setTextColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR] representedColor]];

	[contentCell setBackgroundColorIsStatus:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_AS_STATUS] boolValue]];
	[contentCell setStatusColor:[[prefDict objectForKey:KEY_LIST_THEME_CONTACT_STATUS_COLOR] representedColor]];

	if([contentCell respondsToSelector:@selector(setDrawsGrid:)]){
		[(AIListContactMockieCell *)contentCell setDrawsGrid:[[prefDict objectForKey:KEY_LIST_THEME_GRID_ENABLED] boolValue]];
	}
}

//Outline View data source ---------------------------------------------------------------------------------------------
#pragma mark Outline View data source
//
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
		if (hideRoot){
			return((index >= 0 && index < [contactList containedObjectsCount]) ? [contactList objectAtIndex:index] : nil);
		}else{
			return contactList;
		}
    }else{
        return((index >= 0 && index < [item containedObjectsCount]) ? [item objectAtIndex:index] : nil);
    }
}

//
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
		if (hideRoot){
			return([contactList visibleCount]);
		}else{
			return(1);
		}
    }else{
        return([item visibleCount]);
    }
}

//Before one of our cells gets told to draw, we need to make sure it knows what contact it's drawing for.
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([outlineView isKindOfClass:[AIListOutlineView class]]){
		[(AIListCell *)cell setListObject:item];
		[(AIListCell *)cell setControlView:(AIListOutlineView *)outlineView];
		
		//	
		//	int	icons = [iconArray count];
		//    int	columns = [tableView numberOfColumns];
		//    int index;
		//	
		//    index = (row * columns) + [tableView indexOfTableColumn:tableColumn];
		//	
		//	
		//	
		//    if(index >= 0 && index < icons && (index == selectedIconIndex)){
		//        [cell setHighlighted:YES];
		//    }else{
		//        [cell setHighlighted:NO];
		//    }
		
	}
}

//
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return(@"");
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIListGroup class]]){
        return(YES);
    }else{
        return(NO);
    }
}

//
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    [item setExpanded:state];
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return([item isExpanded]);
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
	BOOL			isGroup = [listObject isKindOfClass:[AIListGroup class]];
	NSArray			*locationsArray = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:(isGroup ? Context_Group_Manage : Context_Contact_Manage)],
		[NSNumber numberWithInt:Context_Contact_Action],
		[NSNumber numberWithInt:Context_Contact_ListAction],
		[NSNumber numberWithInt:Context_Contact_NegativeAction],
		[NSNumber numberWithInt:Context_Contact_Additions], nil];
	
    return([[adium menuController] contextualMenuWithLocations:locationsArray
												 forListObject:listObject]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
	//Kill any selections
	[outlineView deselectAll:nil];
	
	//Begin the drag
	if(dragItems) [dragItems release];
	dragItems = [items retain];
	
	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",@"AIListObjectUniqueIDs",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];
	
	return(YES);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	if(dragItems){
		[dragItems release]; dragItems = nil;
	}
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	//Provide an array of internalObjectIDs which can be used to reference all the dragged contacts
	if ([type isEqualToString:@"AIListObjectUniqueIDs"]){
		
		if (dragItems){
			NSMutableArray	*dragItemsArray = [NSMutableArray array];
			NSEnumerator	*enumerator = [dragItems objectEnumerator];
			AIListObject	*listObject;
			
			while (listObject = [enumerator nextObject]){
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
	
	if([hoveredObject isKindOfClass:[AIListContact class]]){
		[[adium interfaceController] showTooltipForListObject:hoveredObject
												atScreenPoint:screenPoint
													 onWindow:[contactListView window]];
	}else{
		[self hideTooltip];
	}
}

- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint
{
	NSPoint			viewPoint = [contactListView convertPoint:[[contactListView window] convertScreenToBase:screenPoint] fromView:nil];
	AIListObject	*hoveredObject = [contactListView itemAtRow:[contactListView rowAtPoint:viewPoint]];
	
	return(hoveredObject);
}

//Hide tooltip
- (void)hideTooltip
{
	[[adium interfaceController] showTooltipForListObject:nil atScreenPoint:NSMakePoint(0,0) onWindow:nil];
}


//----------------
//For Subclasses
- (void)contactListDesiredSizeChanged:(NSNotification *)notification {};
- (void)updateTransparency {};
- (BOOL)useAliasesInContactListAsRequested{
	return YES;
}
- (BOOL)shouldUseContactTextColors{
	return YES;
}
- (BOOL)shouldShowTooltips{
	return YES;
}
@end
