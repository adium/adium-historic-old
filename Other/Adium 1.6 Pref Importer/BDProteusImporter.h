//
//  BDProteusImporter.h
//  Adium
//
//  Created by Brandon on 2/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDImporter.h"

#define SQLITE [[[NSBundle mainBundle] pathForResource:@"atos" ofType:nil] fileSystemRepresentation]
#define PROTEUS_SCRIPT [[[NSBundle mainBundle] pathForResource:@"proteus2adium.pl" ofType:nil] fileSystemRepresentation]
#define PATH_TO_PROTEUS [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Proteus"]
#define PROTEUS_AWAY_STATUS     7
#define PROTEUS_3_STATUS    [[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Instant Messaging"] stringByAppendingPathComponent:@"Profile"] stringByAppendingPathComponent:@"Status.plist"]
#define PROTEUS_4_STATUS    [[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Proteus"] stringByAppendingPathComponent:@"Profile"] stringByAppendingPathComponent:@"Status.plist"]

@interface BDProteusImporter : BDImporter {

	int perversion;  //LOL_AT_MAH_FUNNAH!!!!1111ONEONEONE
	
}

- (void)setProteusVersion;



@end
