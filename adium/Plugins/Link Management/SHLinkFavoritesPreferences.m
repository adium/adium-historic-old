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

@interface SHLinkFavoritesPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

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
	//
    favorites = nil;

	//Configure our table
    [favoritesTable setDrawsAlternatingRows:YES];
    [favoritesTable setTarget:self];
    [favoritesTable setDoubleAction:@selector(openLinkInBrowser:)];
	
	//Configure our Add/Remove buttons
    [removeButton setImage:[NSImage imageNamed:@"minus" forClass:[self class]]];
    [addButton setImage:[NSImage imageNamed:@"plus" forClass:[self class]]];

	//
    [[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)viewWillClose
{
    [[[AIObject sharedAdiumInstance] notificationCenter] removeObserver:self];    
}

- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil ||
	   [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_LINK_FAVORITES] == 0){
		
		//Get the new favorites
		[favorites release];
		favorites = [[[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES] mutableCopy];

		//Update the favorites table
		[self configureControlDimming];
		[favoritesTable reloadData];
	}
}

- (void)configureControlDimming
{
	[removeButton setEnabled:([favorites count] != 0)];
}


//Favorites Editing ----------------------------------------------------------------------------------------------------
#pragma mark Favorites Editing
- (IBAction)addLink:(id)sender
{
	[SHLinkEditorWindowController showLinkEditorForTextView:nil onWindow:[view window] showFavorites:NO notifyingTarget:self];
}

- (IBAction)removeLink:(id)sender
{
	NSMutableArray	*favoriteArray = [[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];

	if(favoriteArray && [favoritesTable selectedRow] >= 0 && [favoritesTable selectedRow] < [favoriteArray count]){
		favoriteArray = [[favoriteArray mutableCopy] autorelease];
		[favoriteArray removeObjectAtIndex:[favoritesTable selectedRow]];
		[[[AIObject sharedAdiumInstance] preferenceController] setPreference:favoriteArray forKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];
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

//Open the selected link
- (void)openLinkInBrowser:(id)sender
{
    NSString    *urlText = [[self selectedLink] objectForKey:KEY_LINK_URL];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlText]];
}

//Returns the currently selected link
- (NSDictionary *)selectedLink
{
    int selectedRow = [favoritesTable selectedRow];
    if(selectedRow != -1){
        return [favorites objectAtIndex:selectedRow];
    }else{
        return nil;
    }
}


//Favorites Table View Delegate ----------------------------------------------------------------------------------------
#pragma mark Favorites Table View Delegate
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([favorites count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSDictionary	*favorite = [favorites objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"linkText"]) {
        return([favorite objectForKey:KEY_LINK_TITLE]);
    }else if([[tableColumn identifier] isEqualToString:@"urlText"]) {
        return([favorite objectForKey:KEY_LINK_URL]);
    }else{
        return(nil);
    }
}

@end
