//
//  ESOpenMessageWindowContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.



@interface ESOpenMessageWindowContactAlert : ESContactAlert {
    IBOutlet	NSView			*view_details_open_message;
    IBOutlet	NSPopUpButton		*popUp_actionDetails_open_message;
    IBOutlet	NSButton		*button_anotherAccount_open_message;
}

- (IBAction)saveOpenMessageDetails:(id)sender;

@end
