//
//  ESPresetManagementController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/14/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESPresetManagementController : AIWindowController {
	IBOutlet		NSTableView		*tableView_presets;
	
	IBOutlet		NSButton		*button_duplicate;
	IBOutlet		NSButton		*button_delete;
	IBOutlet		NSButton		*button_rename;
	IBOutlet		NSButton		*button_done;
	
	NSArray			*presets;
	NSString		*nameKey;
	
	id				delegate;
	
	NSDictionary	*tempDragPreset;
}

+ (void)managePresets:(NSArray *)inPresets namedByKey:(NSString *)inNameKey onWindow:(NSWindow *)parentWindow withDelegate:(id)inDelegate;

- (IBAction)duplicatePreset:(id)sender;
- (IBAction)deletePreset:(id)sender;
- (IBAction)renamePreset:(id)sender;

@end

@interface NSObject (ESPresetManagementControllerDelegate)
- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)name inPresets:(NSArray *)presets;
- (NSArray *)duplicatePreset:(NSDictionary *)preset inPresets:(NSArray *)presets createdDuplicate:(id *)duplicatePreset;
- (NSArray *)deletePreset:(NSDictionary *)preset inPresets:(NSArray *)presets;
@end