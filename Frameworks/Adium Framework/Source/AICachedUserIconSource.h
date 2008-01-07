//
//  AICachedUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIObject.h>

@interface AICachedUserIconSource : AIObject <AIUserIconSource> {
	
}

+ (BOOL)cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;

@end
