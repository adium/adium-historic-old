//
//  AIServiceIcons.h
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIServiceIcons : NSObject {

}

+ (NSImage *)serviceIconForContact:(AIListContact *)inContact flipped:(BOOL)isFlipped;
+ (BOOL)setActiveServiceIconsFromPath:(NSString *)inPath;

@end
