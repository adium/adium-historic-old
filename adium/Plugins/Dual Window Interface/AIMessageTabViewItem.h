//
//  AIMessageTabViewItem.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIMessageViewController;
@protocol AIInterfaceContainer;

@interface AIMessageTabViewItem : NSTabViewItem <AIInterfaceContainer> {
    AIMessageViewController 	*messageView;
}

+ (AIMessageTabViewItem *)messageTabViewItemWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView;
- (void)makeActive:(id)sender;
- (void)close:(id)sender;
- (NSString *)labelString;
- (void)setAccountSelectionMenuVisible:(BOOL)visible;

@end
