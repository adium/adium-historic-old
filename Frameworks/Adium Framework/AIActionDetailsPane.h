//
//  AIActionDetailsPane.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIModularPane.h"

@interface AIActionDetailsPane : AIModularPane {

}

+ (AIActionDetailsPane *)actionDetailsPane;
+ (AIActionDetailsPane *)actionDetailsPaneForPlugin:(id)inPlugin;
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject;
- (void)configureForEventID:(NSString *)eventID listObject:(AIListObject *)inObject;

- (NSDictionary *)actionDetails;

- (void)detailsForHeaderChanged;

@end
