//
//  ESGaimMeanwhileContactAdditionController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/29/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESGaimRequestAbstractWindowController.h"

@interface ESGaimMeanwhileContactAdditionController : ESGaimRequestAbstractWindowController {
	IBOutlet	NSImageView	*imageView_meanwhile;
	
	IBOutlet	NSTextField	*textField_header;
	IBOutlet	NSTextField	*textField_message;
	
	IBOutlet	NSTableView	*tableView_choices;

	IBOutlet	NSButton	*button_OK;
	IBOutlet	NSButton	*button_cancel;
	
	NSDictionary			*infoDict;
}

+ (ESGaimMeanwhileContactAdditionController *)showContactAdditionListWithDict:(NSDictionary *)inInfoDict;
- (IBAction)pressedButton:(id)sender;

@end
