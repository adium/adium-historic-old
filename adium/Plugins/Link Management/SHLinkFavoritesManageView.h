//
//  SHLinkFavoritesManageView.h
//  Adium
//
//  Created by Stephen Holt on Tue Apr 20 2004.

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface SHLinkFavoritesManageView : NSView {
    IBOutlet    AIAlternatingRowTableView   *table;
    IBOutlet    NSButton                    *removeButton;
                NSArray                     *favorites;
                int                          favoriteCount;
}
-(NSString *)selectedLink;
-(IBAction)removeLink:(id)sender;
-(void)buildLinksList;
- (void)openLinkInBrowser:(id)sender;

@end
