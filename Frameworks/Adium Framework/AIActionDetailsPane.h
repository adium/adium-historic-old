//
//  AIActionDetailsPane.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//

#import "AIModularPane.h"

@interface AIActionDetailsPane : AIModularPane {

}

+ (AIActionDetailsPane *)actionDetailsPane;
+ (AIActionDetailsPane *)actionDetailsPaneForPlugin:(id)inPlugin;
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject;
- (NSDictionary *)actionDetails;

- (void)detailsForHeaderChanged;

@end
