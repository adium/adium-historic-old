//
//  ESSendMessageContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface ESSendMessageAlertDetailPane : AIActionDetailsPane {
	IBOutlet	NSPopUpButton   	*popUp_messageFrom;
	IBOutlet	NSPopUpButton   	*popUp_messageTo;
    IBOutlet	NSButton			*button_useAnotherAccount;
	IBOutlet	NSTextView			*textView_message;

	IBOutlet	NSTextField			*label_To;
	IBOutlet	NSTextField			*label_From;
	IBOutlet	NSTextField			*label_Message;
	
	AIListContact					*toContact;
}

@end
