//
//  BDFireImporter.h
//  Adium
//
//  Created by Brandon on 2/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDImporter.h"


#define SETTINGS_PATH	[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Fire"] stringByAppendingPathComponent:@"FireConfiguration.plist"]

@interface BDFireImporter : BDImporter {

}

-(BOOL)importStatusMessages;
-(BOOL)importLogs;

@end
