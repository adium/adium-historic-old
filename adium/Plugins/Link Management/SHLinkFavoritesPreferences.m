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
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:LINK_MANAGEMENT_DEFAULTS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_LINK_FAVORITES];
	return(defaultsDict);
}

- (void)viewDidLoad
{
    [removeButton setImage:[NSImage imageNamed:@"minus" forClass:[self class]]];
    [addButton setImage:[NSImage imageNamed:@"plus" forClass:[self class]]];
}

- (void)viewWillClose
{
    [favoritesList release];
}

#pragma mark Favorites Editing
- (IBAction)addLink:(id)sender
{
	[SHLinkEditorWindowController showLinkEditorForTextView:nil onWindow:[view window] showFavorites:NO notifyingTarget:self];
}

- (IBAction)removeLink:(id)sender
{
    if([favoritesList favoritesCount] > 0){
		NSMutableArray	*favoriteArray = [[[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES] mutableCopy];
		[favoriteArray removeObject:[favoritesList selectedLink]];
		[[[AIObject sharedAdiumInstance] preferenceController] setPreference:favoriteArray forKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];

        [favoritesList buildLinksList];
    }
}

//Add a new link created by the link editor
- (void)linkEditorLinkDidChange:(NSDictionary *)linkDictionary
{
	NSMutableArray *favoritesDict = [[[adium preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES] mutableCopy];
	if(!favoritesDict) favoritesDict = [[NSMutableArray alloc] init];
	
	[favoritesDict addObject:linkDictionary];
	[[adium preferenceController] setPreference:favoritesDict forKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];
	
	[favoritesDict release];
}

@end
