//
//  ESAnnouncerContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//

#import "ESAnnouncerAlertDetailPane.h"
#import "ESAnnouncerPlugin.h"

@implementation ESAnnouncerAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"AnnouncerContactAlert");    
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails
{
	NSString *textToSpeak = [inDetails objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
	if(textToSpeak){
        [view_textToSpeak setString:textToSpeak];
	}
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	return([NSDictionary dictionaryWithObject:[view_textToSpeak string] forKey:KEY_ANNOUNCER_TEXT_TO_SPEAK]);
}
	
@end
