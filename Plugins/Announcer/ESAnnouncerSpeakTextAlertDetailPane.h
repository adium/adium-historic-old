//
//  ESAnnouncerSpeakTextAlertDetailPane.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.

@class AIActionDetailsPane;

@interface ESAnnouncerSpeakTextAlertDetailPane : AIActionDetailsPane {    
	IBOutlet	NSTextView				*textView_textToSpeak;
	
	IBOutlet	AILocalizationTextField	*textView_textToSpeakLabel;
	IBOutlet	AILocalizationButton	*checkBox_speakEventTime;
}

@end
