//
//  BDImporter.h
//  Adium
//
//  Created by Brandon on 2/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDImporter : NSObject {

	NSImage *clientIcon;
	
}

- (NSImage *)iconAtSize:(int)iconSize;


@end
