//
//  AIContactInfoPane.h
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIContactController.h"

@interface AIContactInfoPane : AIModularPane {

}

+ (AIContactInfoPane *)contactInfoPane;
- (void)configureForListObject:(AIListObject *)inListObject;
- (CONTACT_INFO_CATEGORY)contactInfoCategory;

@end
