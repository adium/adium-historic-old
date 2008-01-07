//
//  AIManuallySetUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIObject.h>

@interface AIManuallySetUserIconSource : AIObject <AIUserIconSource> {

}

- (void)setManuallySetUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSData *)manuallySetUserIconDataForObject:(AIListObject *)inObject;

@end
