//
//  CSNewContactAlertWindowController.h
//  Adium
//
//  Created by Chris Serino on Wed Mar 31 2004.
//

@class ESContactAlerts;

@protocol NewContactAlertDelegate

- (void)contactAlertWindowFinished:(id)sender didCreate:(BOOL)created;

@end

@interface CSNewContactAlertWindowController : AIWindowController {
	IBOutlet NSView					*view_auxilary;
	IBOutlet NSPopUpButton			*popUp_event;
	IBOutlet NSPopUpButton			*popUp_action;
	IBOutlet NSPopUpButton			*popUp_contact;
	
	BOOL							editing;
	
	ESContactAlerts					*instance;
	id								delegate;
}
- (id)initWithInstance:(ESContactAlerts *)inInstance editing:(BOOL)inEditing;

- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)contactChange:(id)sender;

- (void)setContactAlertsInstance:(ESContactAlerts *)inInstance;
- (ESContactAlerts *)contactAlertsInstance;

- (void)setDelegate:(id)inDelegate;
- (id)delegate;
@end
