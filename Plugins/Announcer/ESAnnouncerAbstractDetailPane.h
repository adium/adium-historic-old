//
//  ESAnnouncerAbstractDetailPane.h
//  Adium
//
//  Created by Evan Schoenberg on 1/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESAnnouncerPlugin.h"

@class AIActionDetailsPane;

@interface ESAnnouncerAbstractDetailPane : AIActionDetailsPane {
	
	IBOutlet	AILocalizationButton	*checkBox_speakEventTime;
	IBOutlet	AILocalizationButton	*checkBox_speakContactName;
	IBOutlet	NSPopUpButton			*popUp_voices;
	IBOutlet	NSSlider				*slider_pitch;
	IBOutlet	NSSlider				*slider_rate;
	
	IBOutlet	NSTextField				*label_voice;
	IBOutlet	NSTextField				*label_pitch;
	IBOutlet	NSTextField				*label_rate;
}

- (NSDictionary *)actionDetailsFromDict:(NSMutableDictionary *)actionDetails;
- (NSString *)defaultDetailsKey;

@end
