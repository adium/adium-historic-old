//
//  SHLinkFavoritesManageView.m
//  Adium
//
//  Created by Stephen Holt on Tue Apr 20 2004.

#import "SHLinkEditorWindowController.h"
#import "SHLinkFavoritesManageView.h"


@interface SHLinkFavoritesManageView (PRIVATE)
- (void)configureControlDimming;
- (void)_writePrefs;
@end

@implementation SHLinkFavoritesManageView

-(void)awakeFromNib
{
    favorites = nil;
    [table setDrawsAlternatingRows:YES];
    [table setTarget:self];
    [table setDoubleAction:@selector(openLinkInBrowser:)];
    [self buildLinksList];
    [[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)dealloc
{
    [[[AIObject sharedAdiumInstance] notificationCenter] removeObserver:self];
    [self _writePrefs];
    [super dealloc];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    [self buildLinksList];
}

- (void)buildLinksList
{
    favorites = [[[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES] mutableCopy];
    favoriteCount = [favorites count];
    [self configureControlDimming];
    [table reloadData];
}

- (void)_writePrefs
{
    [[[AIObject sharedAdiumInstance] preferenceController] setPreference:favorites forKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return favoriteCount;
}

- (int)favoritesCount
{
    return favoriteCount;
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

-(NSDictionary *)selectedLink
{
    int selectedRow = [table selectedRow];
    if (selectedRow != -1) {
        return [favorites objectAtIndex:selectedRow];
    }else{
        return nil;
    }
}

- (void)configureControlDimming
{
    if([favorites count] == 0){
        [removeButton setEnabled:NO];
    }else{
        [removeButton setEnabled:YES];
    }
}

- (void)openLinkInBrowser:(id)sender
{
    NSString    *urlText = [[self selectedLink] objectForKey:KEY_LINK_URL];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlText]];
}

@end
