//
//  AIActionDetailsPane.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIModularPane.h"

@interface AIActionDetailsPane : AIModularPane {

}

+ (AIActionDetailsPane *)actionDetailsPane;
+ (AIActionDetailsPane *)actionDetailsPaneForPlugin:(id)inPlugin;
- (void)configureForActionDetails:(NSDictionary *)inDetails;
- (NSDictionary *)actionDetails;

@end
