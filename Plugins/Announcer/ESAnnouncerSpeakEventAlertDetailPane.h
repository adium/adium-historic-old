//
//  ESAnnouncerSpeakEventAlertDetailPane.h
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

@class AIActionDetailsPane;

@interface ESAnnouncerSpeakEventAlertDetailPane : AIActionDetailsPane {
	IBOutlet	AILocalizationButton	*checkBox_speakEventTime;
	IBOutlet	AILocalizationButton	*checkBox_speakContactName;
}

@end
