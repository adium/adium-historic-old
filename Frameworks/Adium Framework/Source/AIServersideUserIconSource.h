//
//  AIServersideUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIObject.h>

@interface AIServersideUserIconSource : AIObject <AIUserIconSource> {
	NSMutableDictionary *serversideIconDataCache;
	BOOL				gettingServersideData;
}

- (void)setServersideUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSData *)serversideUserIconDataForObject:(AIListObject *)inObject;

@end
