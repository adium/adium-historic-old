//
//  AIListLayoutWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#define PREF_GROUP_LIST_LAYOUT			@"List Layout"
#define KEY_LIST_LAYOUT_ALIGNMENT		@"Contact Text Alignment"
#define KEY_LIST_LAYOUT_GROUP_ALIGNMENT	@"Group Text Alignment"


@interface AIListLayoutWindowController : AIWindowController {
	IBOutlet		NSPopUpButton		*popUp_contactTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_groupTextAlignment;
	
}

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;

@end
