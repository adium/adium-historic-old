//
//  ESAnnouncerSpeakTextAlertDetailPane.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESAnnouncerAbstractDetailPane.h"

@interface ESAnnouncerSpeakTextAlertDetailPane : ESAnnouncerAbstractDetailPane {    
	IBOutlet	NSTextView				*textView_textToSpeak;
	
	IBOutlet	AILocalizationTextField	*textView_textToSpeakLabel;
}

@end
