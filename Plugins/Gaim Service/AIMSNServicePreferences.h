//
//  AIMSNServicePreferences.h
//  Adium
//
//  Created by Adam Iser on 10/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIMSNServicePreferences : AIPreferencePane {
	IBOutlet		NSButton		*checkBox_treatDisplayNamesAsStatus;
	IBOutlet		NSButton		*checkBox_conversationClosed;
	IBOutlet		NSButton		*checkBox_conversationTimedOut;
	
}

@end
