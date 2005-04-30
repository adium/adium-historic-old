//
//  ESGaimMeanwhileContactAdditionController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/29/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESGaimMeanwhileContactAdditionController : AIWindowController {
	IBOutlet	NSImageView	*imageView_meanwhile;
	
	IBOutlet	NSTextField	*textField_header;
	IBOutlet	NSTextField	*textField_message;
	
	IBOutlet	NSTableView	*tableView_choices;

	IBOutlet	NSButton	*button_OK;
	IBOutlet	NSButton	*button_cancel;
	
	NSDictionary			*infoDict;
}

- (IBAction)pressedButton:(id)sender;

@end
