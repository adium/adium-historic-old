//
//  CSNewContactAlertWindowController.h
//  Adium
//
//  Created by Chris Serino on Wed Mar 31 2004.
//

@class AIImageTextView;

@interface CSNewContactAlertWindowController : AIWindowController {
	IBOutlet NSView					*view_auxiliary;
	IBOutlet NSPopUpButton			*popUp_event;
	IBOutlet NSPopUpButton			*popUp_action;
	IBOutlet NSButton				*checkbox_oneTime;
	
	AIActionDetailsPane				*detailsPane;
	NSView							*detailsView;
	NSMutableDictionary				*alert;

	id								target;
	NSDictionary					*oldAlert;

	AIListObject					*listObject;
	
	BOOL							configureForGlobal;
	
	IBOutlet	AIImageTextView		*headerView;
}

+ (void)editAlert:(NSDictionary *)inAlert
	forListObject:(AIListObject *)inObject
		 onWindow:(NSWindow *)parentWindow
  notifyingTarget:(id)inTarget 
		 oldAlert:(NSDictionary *)inOldAlert
	configureForGlobal:(BOOL)inConfigureForGlobal;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
