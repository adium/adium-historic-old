//
//  SHLinkFavoritesPreferences.h
//  Adium
//
//  Created by Stephen Holt on Tue Apr 20 2004.

#import "SHLinkFavoritesManageView.h"


@interface SHLinkFavoritesPreferences : AIPreferencePane {

    IBOutlet AIPlasticButton            *removeButton;
    IBOutlet AIPlasticButton            *addButton;
    
    IBOutlet SHLinkFavoritesManageView  *favoritesList;

}

- (IBAction)addLink:(id)sender;
- (IBAction)removeLink:(id)sender;

@end
