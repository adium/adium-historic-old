//
//  AIAbstractListWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/21/04.
//

#import "AIAbstractListWindowController.h"

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

@implementation AIAbstractListWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[super initWithWindowNibName:windowNibName];
	
	hideRoot = YES;
	
	return(self);
}

//Dealloc
- (void)dealloc
{
	[contactListView setDelegate:nil];
	if (tooltipTracker){
		[tooltipTracker setDelegate:nil];
		[tooltipTracker release]; tooltipTracker = nil;
	}

	[groupCell release];
	[contentCell release];
	
    [super dealloc];
}

//Setup the window after it has loaded
- (void)windowDidLoad
{
    //Configure the contact list view
	tooltipTracker = [[AISmoothTooltipTracker smoothTooltipTrackerForView:scrollView_contactList withDelegate:self] retain];
	[[[contactListView tableColumns] objectAtIndex:0] setDataCell:[[AIListContactCell alloc] init]];
	
	//Targeting
    [contactListView setTarget:self];
	[contactListView setDoubleAction:@selector(performDefaultActionOnSelectedItem:)];
	[scrollView_contactList setDrawsBackground:NO];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];

	//Dragging
	[contactListView registerForDraggedTypes:[NSArray arrayWithObject:@"AIListObject"]];
}

- (BOOL)windowShouldClose:(id)sender
{
	[tooltipTracker setDelegate:nil];
	[tooltipTracker release]; tooltipTracker = nil;
	
	return YES;
}

- (void)setContactListRoot:(AIListObject <AIContainingObject> *)newContactListRoot
{
	[contactList release]; contactList = [newContactListRoot retain];
	[contactListView reloadData];
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
	[self performDefaultActionOnSelectedContact:selectedObject withSender:sender];
}

//Preferences ---------------------------------------------
#pragma mark Preferences
- (void)updateLayoutFromPrefDict:(NSDictionary *)prefDict
{
	int				windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
	float			backgroundAlpha	= [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue];
	LIST_CELL_STYLE	contactCellStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE] intValue];
	Class			cellClass;
	
	//Group Cell
	[groupCell release];
	if(windowStyle == WINDOW_STYLE_MOCKIE){
		groupCell = [[AIListGroupMockieCell alloc] init];
	}else{
		switch([[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_CELL_STYLE] intValue]){
			case CELL_STYLE_STANDARD: 	cellClass = [AIListGroupCell class]; break;
			case CELL_STYLE_BRICK: 		cellClass = [AIListGroupGradientCell class]; break;
			case CELL_STYLE_BUBBLE: 	cellClass = [AIListGroupBubbleCell class]; break;
			default: /*case CELL_STYLE_BUBBLE_FIT:*/ cellClass = [AIListGroupBubbleToFitCell class]; break;
		}
		groupCell = [[cellClass alloc] init];	
	}
	[contactListView setGroupCell:groupCell];
	
	//Contact Cell
	//Disallow standard and brick for pillows
	if(windowStyle == WINDOW_STYLE_PILLOWS &&
	   (contactCellStyle == CELL_STYLE_STANDARD || contactCellStyle == CELL_STYLE_BRICK)){
		contactCellStyle = CELL_STYLE_BUBBLE;
	}
	//Special cell for mockie
	[contentCell release];
	if(windowStyle == WINDOW_STYLE_MOCKIE){
		contentCell = [[AIListContactMockieCell alloc] init];
	}else{
		switch(contactCellStyle){
			case CELL_STYLE_STANDARD: 	cellClass = [AIListContactCell class]; break;
			case CELL_STYLE_BUBBLE: 	cellClass = [AIListContactBubbleCell class]; break;
			default:/*case CELL_STYLE_BUBBLE_FIT*/ cellClass = [AIListContactBubbleToFitCell class]; break;
		}
		contentCell = [[cellClass alloc] init];
	}
	[contactListView setContentCell:contentCell];
	[contentCell setUseAliasesAsRequested:[self useAliasesInContactListAsRequested]];
	
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
	
	//Fonts
	[contentCell setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_FONT] representedFont]];
	[contentCell setStatusFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_FONT] representedFont]];
	[groupCell setFont:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_FONT] representedFont]];
	
	//Bubbles special cases
	if(windowStyle != WINDOW_STYLE_MOCKIE &&
	   (contactCellStyle == CELL_STYLE_BUBBLE || contactCellStyle == CELL_STYLE_BUBBLE_FIT)){
		[contentCell setSplitVerticalSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		[contentCell setLeftSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_LEFT_INDENT] intValue]];
		[contentCell setRightSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_RIGHT_INDENT] intValue]];
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
	if(windowStyle == WINDOW_STYLE_MOCKIE || windowStyle == WINDOW_STYLE_PILLOWS){
		if ([contentCell respondsToSelector:@selector(setBackgroundOpacity:)]){
			[contentCell setBackgroundOpacity:backgroundAlpha];
		}
		if ([contactListView respondsToSelector:@selector(setDrawsBackground:)]){
			[contactListView setDrawsBackground:NO];
		}
	}else{
		if ([contactListView respondsToSelector:@selector(setDrawsBackground:)]){
			[contactListView setDrawsBackground:YES];
		}
	}
	
	//Shadow
	[[self window] setHasShadow:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_SHADOWED] boolValue]];
	
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
	if(windowStyle == WINDOW_STYLE_MOCKIE || windowStyle == WINDOW_STYLE_PILLOWS){
		backgroundAlpha = 0.0;
		[contactListView setDrawsAlternatingRows:NO];
	}else{
		[contactListView setDrawsAlternatingRows:(backgroundAlpha == 0.0 ? NO : [[themeDict objectForKey:KEY_LIST_THEME_GRID_ENABLED] boolValue])];
	}
	
	//Transparency.  Bye bye CPU cycles, I'll miss you!
	[[self window] setOpaque:(backgroundAlpha == 1.0)];
	if ([contactListView respondsToSelector:@selector(setUpdateShadowsWhileDrawing:)]){
		[contactListView setUpdateShadowsWhileDrawing:(backgroundAlpha < 0.8)];
	}
}

- (void)updateCellRelatedThemePreferencesFromDict:(NSDictionary *)prefDict
{
	if ([groupCell isKindOfClass:[AIListGroupGradientCell class]]){

		[(AIListGroupGradientCell *)groupCell setBackgroundColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND] representedColor]
												   gradientColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT] representedColor]];

		[(AIListGroupGradientCell *)groupCell setShadowColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_SHADOW_COLOR] representedColor]];
	}
	
	if([[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_GROUP_CELL_STYLE
												 group:PREF_GROUP_LIST_LAYOUT] intValue] == CELL_STYLE_STANDARD){
		[groupCell setTextColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR] representedColor]];
	}else{
		[groupCell setTextColor:[[prefDict objectForKey:KEY_LIST_THEME_GROUP_TEXT_COLOR_INVERTED] representedColor]];
	}
	
	[contentCell setBackgroundColorIsStatus:[[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_AS_STATUS] boolValue]];
	[contentCell setStatusColor:[[prefDict objectForKey:KEY_LIST_THEME_CONTACT_STATUS_COLOR] representedColor]];
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
			return([(AIListGroup *)contactList visibleCount]);
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
	if (outlineView == contactListView){
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
	AIListObject	*listObject = (AIListObject *)[contactListView firstSelectedItem];
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
	
	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];
	
	return(YES);
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
													 onWindow:[self window]];
	}else{
		[self hideTooltip];
	}
}

- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint
{
	NSPoint			viewPoint = [contactListView convertPoint:[[self window] convertScreenToBase:screenPoint] fromView:nil];
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
- (IBAction)performDefaultActionOnSelectedContact:(AIListObject *)selectedObject withSender:(id)sender {};
- (BOOL)useAliasesInContactListAsRequested{
	return YES;
}

@end
