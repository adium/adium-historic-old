//
//  ESPresetManagementController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/14/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESPresetManagementController.h"

#define	PRESET_DRAG_TYPE @"Adium:PresetDrag"

@interface ESPresetManagementController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName presets:(NSArray *)inPresets namedByKey:(NSString *)inNameKey withDelegate:(id)inDelegate;
- (void)configureControlDimming;
@end

/*
 * @class ESPresetManagementController
 * @brief Generic controller for managing presets
 */
@implementation ESPresetManagementController

/*
 * @brief Begin managing presets
 *
 * @param inPresets An array of either NSString or NSDictionary objects.
 * @param inNameKey If inPresets contains NSDictionary objects, the key used to look up the name ot present to the user.
 * @param parentWindow A window on which to show the preset manager as a sheet
 * @param inDelegate The delegate for preset management.  It must implement all methods in the ESPresetManagementControllerDelegate informal protocol.
 */
+ (void)managePresets:(NSArray *)inPresets namedByKey:(NSString *)inNameKey onWindow:(NSWindow *)parentWindow withDelegate:(id)inDelegate
{
	ESPresetManagementController	*controller;
	
	NSParameterAssert([inDelegate respondsToSelector:@selector(renamePreset:toName:inPresets:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(duplicatePreset:inPresets:createdDuplicate:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(deletePreset:inPresets:)]);
	
	//(movePreset:toIndex:referencePresetArray:)
	controller = [[self alloc] initWithWindowNibName:@"PresetManagement"
											 presets:inPresets
										  namedByKey:inNameKey
										withDelegate:inDelegate];
	
	if(parentWindow){
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];

	}else{
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}
}

- (id)initWithWindowNibName:(NSString *)windowNibName presets:(NSArray *)inPresets namedByKey:(NSString *)inNameKey withDelegate:(id)inDelegate
{
    if(self = [super initWithWindowNibName:windowNibName]){
		presets = [inPresets retain];
		nameKey = [inNameKey retain];
		delegate = [inDelegate retain];
	}
	
	return(self);	
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[presets release];
	[nameKey release];
	
	[super dealloc];
}

/*
 * @brief Window did load
 */
- (void)windowDidLoad
{
	//Enable dragging of presets
	[tableView_presets registerForDraggedTypes:[NSArray arrayWithObject:PRESET_DRAG_TYPE]];

	[self configureControlDimming];
}

/*!
 * @brief Okay
 *
 * Close the window
 */
- (IBAction)okay:(id)sender
{
	
	[self closeWindow:nil];
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
    [sheet orderOut:nil];
}

/*!
 * @brief As the window closes, release this controller instance
 *
 * The instance retained itself (rather, was not autoreleased when created) so it could function independently.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
		
	[self autorelease];
}

/*
 * @brief Duplicate the selected preset
 */
- (IBAction)duplicatePreset:(id)sender
{
	int selectedRow = [tableView_presets selectedRow];
	if(selectedRow != -1){
		id duplicatePreset, selectedPreset;
		int duplicatePresetIndex;
		
		selectedPreset = [presets objectAtIndex:selectedRow];
		
		//Inform the delegate of the duplicate request
		NSArray	*newPresets;
		newPresets = [delegate duplicatePreset:selectedPreset 
									 inPresets:presets
							  createdDuplicate:&duplicatePreset];
		
		[presets autorelease]; presets = [newPresets retain];
		
		//The delegate returned a potentially changed presets array; reload table data
		[tableView_presets reloadData];

		//Set up for a rename of the new duplicate if possible
		duplicatePresetIndex = [presets indexOfObject:duplicatePreset];
		if(duplicatePresetIndex != NSNotFound){
			[tableView_presets selectRow:duplicatePresetIndex byExtendingSelection:NO];
			[tableView_presets editColumn:0
									  row:duplicatePresetIndex
								withEvent:nil
								   select:YES];
		}
	}	
}

/*
 * @brief Delete the selected preset
 */
- (IBAction)deletePreset:(id)sender
{
	int selectedRow = [tableView_presets selectedRow];
	if(selectedRow != -1){
		id selectedPreset = [presets objectAtIndex:selectedRow];

		//Inform the delegate of the deletion
		NSArray	*newPresets;
		newPresets = [delegate deletePreset:selectedPreset inPresets:presets];
		[presets autorelease]; presets = [newPresets retain];
		
		//The delegate returned a potentially changed presets array; reload table data
		[tableView_presets reloadData];
	}
}

/*
 * @brief Rename the selected preset
 */
- (IBAction)renamePreset:(id)sender
{
	int selectedRow = [tableView_presets selectedRow];
	if(selectedRow != -1){
		[tableView_presets editColumn:0 row:selectedRow withEvent:nil select:YES];
	}
}

/*
 * @brief Configure control dimming
 */
- (void)configureControlDimming
{
	int selectedRow = [tableView_presets selectedRow];
	
	if(selectedRow != -1){
		id	preset = [presets objectAtIndex:selectedRow];
		BOOL	allowDelete = (![delegate respondsToSelector:@selector(allowDeleteOfPreset:)] ||
							   [delegate allowDeleteOfPreset:preset]);
		BOOL	allowRename = (![delegate respondsToSelector:@selector(allowRenameOfPreset:)] ||
							   [delegate allowRenameOfPreset:preset]);

		[button_delete setEnabled:allowDelete];
		[button_rename setEnabled:allowRename];
		
		//Always allow duplication
		[button_duplicate setEnabled:YES];
		
	}else{
		[button_duplicate setEnabled:NO];
		[button_delete setEnabled:NO];
		[button_rename setEnabled:NO];
	}
}

#pragma mark Table view data source and delegate

//State List Table Delegate --------------------------------------------------------------------------------------------
#pragma mark State List (Table Delegate)
/*!
 * @brief Number of rows
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([presets count]);
}

/*!
 * @brief Table values
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	id	preset = [presets objectAtIndex:row];

	if([preset isKindOfClass:[NSDictionary class]]){
		return [preset objectForKey:(nameKey ? nameKey : @"Name")];
		
	}else if([preset isKindOfClass:[NSString class]]){
		return preset;
	}
	
	return(@"");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)row
{
	if([anObject isKindOfClass:[NSString class]]){
		id	preset = [presets objectAtIndex:row];
		
		//Inform the delegate of the rename
		NSArray	*newPresets;

		newPresets = [delegate renamePreset:preset toName:(NSString *)anObject inPresets:presets];
		[presets autorelease]; presets = [newPresets retain];
		
		//The delegate returned a potentially changed presets array; reload table data
		[tableView_presets reloadData];
	}
}

/*!
 * @brief Delete the selected row
 */
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deletePreset:nil];
}

/*!
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self configureControlDimming];
}

/*!
 * @brief Drag start
 *
 * Only allow the drag to start if the delegate responds to @selector(movePreset:toIndex:inPresets:)
 */
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
	if([delegate respondsToSelector:@selector(movePreset:toIndex:inPresets:presetAfterMove:)]){
		[tempDragPreset release];
		tempDragPreset = [[presets objectAtIndex:[[rows objectAtIndex:0] intValue]] retain];
		
		[pboard declareTypes:[NSArray arrayWithObject:PRESET_DRAG_TYPE] owner:self];
		[pboard setString:@"Preset" forType:PRESET_DRAG_TYPE]; //Arbitrary state
		
		return(YES);
	}else{
		return(NO);
	}
}

/*!
 * @brief Drag validate
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if(op == NSTableViewDropAbove && row != -1){
        return(NSDragOperationPrivate);
    }else{
        return(NSDragOperationNone);
    }
}

/*!
 * @brief Drag complete
 */
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:PRESET_DRAG_TYPE]];
	BOOL		success = NO;
    if([avaliableType isEqualToString:PRESET_DRAG_TYPE]){		
		NSDictionary	*presetAfterMove = tempDragPreset;
		
		//Inform the delegate of the move; it may pass back a changed preset by reference
		NSArray	*newPresets;
		newPresets = [delegate movePreset:tempDragPreset toIndex:row inPresets:presets presetAfterMove:&presetAfterMove];
		[presets autorelease]; presets = [newPresets retain];

		//Reload with the new data
		[tableView_presets reloadData];
		
		//Reselect the moved preset if possible
		int movedPresetIndex = [presets indexOfObject:presetAfterMove];
		if(movedPresetIndex != NSNotFound){
			[tableView_presets selectRow:movedPresetIndex byExtendingSelection:NO];
		}

        success = YES;
    }
	
	[tempDragPreset release]; tempDragPreset = nil;
	
	return success;
}

@end
