//
//  AITabViewAdditions.h
//  Adium
//
//  Created by Adam Iser on Wed Dec 11 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTabView (AITabViewAdditions)
- (NSTabViewItem *)tabViewItemWithIdentifier:(id)identifier;
@end
