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
	IBOutlet NSButton				*checkbox_oneTime;
	
	AIActionDetailsPane				*detailsPane;
	NSView							*detailsView;
	NSMutableDictionary				*alert;
	id								target;
	id								userInfo;
	
	AIListObject					*listObject;
}

+ (void)editAlert:(NSDictionary *)inAlert forListObject:(AIListObject *)inListObject onWindow:(NSWindow *)parentWindow notifyingTarget:(id)inTarget userInfo:(id)inUserInfo;
- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
