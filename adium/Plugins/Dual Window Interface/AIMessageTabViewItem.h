//
//  AIMessageTabViewItem.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIMessageViewController, AIAdium;
@protocol AIInterfaceContainer;

@interface AIMessageTabViewItem : NSTabViewItem <AIInterfaceContainer> {
    AIMessageViewController 	*messageView;
    AIAdium			*owner;
}

+ (AIMessageTabViewItem *)messageTabViewItemWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner;
- (void)makeActive:(id)sender;
- (void)close:(id)sender;
- (NSString *)labelString;
- (AIMessageViewController *)messageViewController;
- (void)tabViewItemWasSelected;

@end
