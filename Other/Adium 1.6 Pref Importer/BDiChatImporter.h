//
//  BDiChatImporter.h
//  Adium
//
//  Created by Brandon on 2/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDImporter.h"



#define SETTINGS_PATH	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:@"com.apple.iChat.plist"]


@interface BDiChatImporter : BDImporter {
	
}

@end
