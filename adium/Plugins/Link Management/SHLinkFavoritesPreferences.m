//
//  SHLinkFavoritesPreferences.m
//  Adium
//
//  Created by Stephen Holt on Tue Apr 20 2004.

#import "SHLinkManagementPlugin.h"
#import "SHLinkEditorWindowController.h"
#import "SHLinkFavoritesPreferences.h"

#define LINKS_PREF_NIB  @"LinkPreferences"
#define LINKS_PREF_LABEL AILocalizedString(@"Link Favorites",nil)

@implementation SHLinkFavoritesPreferences

- (PREFERENCE_CATEGORY)category
{
    return(AIPref_Advanced_Other);
}

- (NSString *)label{
    return(@"Link Favorites");
}

- (NSString *)nibName{
    return(LINKS_PREF_NIB);
}

- (NSDictionary *)restorablePreferences
{
    return(nil);
}

- (void)viewDidLoad
{
    [removeButton setImage:[NSImage imageNamed:@"minus" forClass:[self class]]];
}

- (void)viewWillClose
{
    [favoritesList release];
}

@end
