//
//  SHLinkFavoritesManageView.h
//  Adium
//
//  Created by Stephen Holt on Tue Apr 20 2004.

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@class SHLinkEditorWindowController;

@interface SHLinkFavoritesManageView : NSView {
    IBOutlet    AIAlternatingRowTableView   *table;
    IBOutlet    NSButton                    *removeButton;
    IBOutlet    NSButton                    *addButton;
                NSArray                     *favorites;
                int                          favoriteCount;
}
- (NSString *)selectedLink;
- (void)buildLinksList;
- (void)openLinkInBrowser:(id)sender;

@end
