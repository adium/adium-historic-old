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
    favorites =  [[[[[AIObject sharedAdiumInstance] preferenceController] preferencesForGroup:PREF_GROUP_LINK_FAVORITES] allKeys] copy];
    favoriteCount = [favorites count];
    [self configureControlDimming];
    [table reloadData];
}

- (void)_writePrefs
{
    NSEnumerator    *enumerator = [favorites objectEnumerator];
    NSString        *key = nil;
    NSDictionary    *prefDict = [[[AIObject sharedAdiumInstance] preferenceController] preferencesForGroup:PREF_GROUP_LINK_FAVORITES];
    while((key = [enumerator nextObject])){
        [[[AIObject sharedAdiumInstance] preferenceController] setPreference:[prefDict objectForKey:key]
                                                                      forKey:key
                                                                       group:PREF_GROUP_LINK_FAVORITES];
    }
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
    NSString    *linkText = [favorites objectAtIndex:row];
    NSString    *urlText = [[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:[favorites objectAtIndex:row] group:PREF_GROUP_LINK_FAVORITES];
    
    if([[tableColumn identifier] isEqualToString:@"linkText"]) {
        return(linkText);
    }else if([[tableColumn identifier] isEqualToString:@"urlText"]) {
        return(urlText);
    }else{
        return(nil);
    }
}

-(NSString *)selectedLink
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
    NSString    *urlText = [[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:[self selectedLink] group:PREF_GROUP_LINK_FAVORITES];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlText]];
}

@end
