//
//  AIExtendedStatusPlugin.h
//  Adium
//
//  Created by Adam Iser on 9/7/04.
//

#import <Cocoa/Cocoa.h>

@protocol AIListObjectObserver;

@interface AIExtendedStatusPlugin : AIPlugin <AIListObjectObserver> {
	BOOL	showIdle;
	BOOL	showStatus;
}

- (NSString *)idleStringForSeconds:(int)seconds;

@end
