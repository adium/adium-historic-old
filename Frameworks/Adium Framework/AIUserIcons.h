//
//  AIUserIcons.h
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//

#import <Cocoa/Cocoa.h>


@interface AIUserIcons : NSObject {

}

+ (NSImage *)listUserIconForContact:(AIListContact *)inContact size:(NSSize)size;
+ (NSImage *)menuUserIconForObject:(AIListObject *)inObject;

+ (void)setListUserIconSize:(NSSize)inSize;
+ (void)flushListUserIconCache;
+ (void)flushCacheForContact:(AIListContact *)inContact;

@end
