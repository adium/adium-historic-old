//
//  AISystemTabRendering.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AISystemTabRendering : NSObject {
    
}

+ (NSImage *)tabFrontLeft;
+ (NSImage *)tabFrontMiddle;
+ (NSImage *)tabFrontRight;

+ (NSImage *)tabBackLeft;
+ (NSImage *)tabBackMiddle;
+ (NSImage *)tabBackRight;

+ (NSImage *)tabPushLeft;
+ (NSImage *)tabPushMiddle;
+ (NSImage *)tabPushRight;

+ (NSImage *)tabBackground;

@end

@interface AIFakeTabView : NSTabView {

}

@end

@interface AIFakeTabViewItem : NSTabViewItem {
    NSTabState		tabState;
}

- (void)setState:(NSTabState)inTabState;

@end

@interface AIFakeWindow : NSWindow {
    BOOL		isKey;
}

- (void)setIsKey:(BOOL)inIsKey;

@end
