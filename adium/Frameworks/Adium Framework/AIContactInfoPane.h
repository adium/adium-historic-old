//
//  AIContactInfoPane.h
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIContactInfoPane : AIModularPane {

}

+ (AIContactInfoPane *)contactInfoPane;
- (void)configureForListObject:(AIListObject *)inListObject;

@end
