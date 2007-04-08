//
//  ESPurpleMeanwhileContactAdditionController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/29/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleRequestAbstractWindowController.h"

@interface ESPurpleMeanwhileContactAdditionController : ESPurpleRequestAbstractWindowController {
	IBOutlet	NSImageView	*imageView_meanwhile;
	
	IBOutlet	NSTextField	*textField_header;
	IBOutlet	NSTextField	*textField_message;
	
	IBOutlet	NSTableView	*tableView_choices;

	IBOutlet	NSButton	*button_OK;
	IBOutlet	NSButton	*button_cancel;
	
	NSDictionary			*infoDict;
}

+ (ESPurpleMeanwhileContactAdditionController *)showContactAdditionListWithDict:(NSDictionary *)inInfoDict;
- (IBAction)pressedButton:(id)sender;

@end
