//
//  SHLinkFavoritesPreferences.h
//  Adium
//
//  Created by Stephen Holt on Tue Apr 20 2004.

#import "SHLinkFavoritesManageView.h"


@interface SHLinkFavoritesPreferences : AIPreferencePane {
    IBOutlet AIAlternatingRowTableView  *favoritesTable;

    IBOutlet AIPlasticButton            *removeButton;
    IBOutlet AIPlasticButton            *addButton;

	NSMutableArray				*favorites;
}

- (IBAction)addLink:(id)sender;
- (IBAction)removeLink:(id)sender;
- (NSDictionary *)selectedLink;

@end
