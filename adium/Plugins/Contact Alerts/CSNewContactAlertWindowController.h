//
//  CSNewContactAlertWindowController.h
//  Adium
//
//  Created by Chris Serino on Wed Mar 31 2004.
//

@interface CSNewContactAlertWindowController : AIWindowController {
	IBOutlet NSView					*view_auxiliary;
	IBOutlet NSPopUpButton			*popUp_event;
	IBOutlet NSPopUpButton			*popUp_action;
	
	AIActionDetailsPane				*detailsPane;
	NSView							*detailsView;
	NSMutableDictionary				*alert;
	id								target;
	id								userInfo;
}

+ (void)editAlert:(NSDictionary *)inAlert onWindow:(NSWindow *)parentWindow notifyingTarget:(id)inTarget userInfo:(id)userInfo;
- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
