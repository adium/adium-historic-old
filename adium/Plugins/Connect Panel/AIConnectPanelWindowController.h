//
//  AIConnectPanelWindowController.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIConnectPanelWindowController : AIWindowController {
	IBOutlet	NSPopUpButton		*popupMenu_serviceList;
}

+ (AIConnectPanelWindowController *)connectPanelWindowController;
- (IBAction)connect:(id)sender;
- (IBAction)showAccounts:(id)sender;

@end
