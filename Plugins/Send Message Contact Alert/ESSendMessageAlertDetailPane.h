//
//  ESSendMessageContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.

@interface ESSendMessageAlertDetailPane : AIActionDetailsPane {
	IBOutlet	NSPopUpButton   	*popUp_messageFrom;
	IBOutlet	NSPopUpButton   	*popUp_messageTo;
    IBOutlet	NSButton			*button_useAnotherAccount;
	IBOutlet	NSTextView			*textView_message;

	AIListObject					*toListObject;
}

@end
