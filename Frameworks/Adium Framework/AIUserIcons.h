//
//  AIUserIcons.h
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIUserIcons : NSObject {

}

+ (NSImage *)listUserIconForContact:(AIListContact *)inContact;
+ (void)setListUserIconSize:(NSSize)inSize;
+ (void)flushListUserIconCache;

@end
