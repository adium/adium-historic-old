//
//  ESGaimAuthorizationRequestWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 5/18/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimRequestAbstractWindowController.h"

@interface ESGaimAuthorizationRequestWindowController : ESGaimRequestAbstractWindowController {
	IBOutlet	NSTextField		*textField_header;
	IBOutlet	NSTextField		*textField_message;

	IBOutlet	NSButton		*button_authorize;
	IBOutlet	NSButton		*button_deny;
	IBOutlet	NSButton		*checkBox_addToList;
	
	NSDictionary				*infoDict;
}

+ (ESGaimAuthorizationRequestWindowController *)showAuthorizationRequestWithDict:(NSDictionary *)inInfoDict;
- (IBAction)authorize:(id)sender;

@end
