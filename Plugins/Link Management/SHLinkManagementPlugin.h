//
//  SHLinkManagementPlugin.h
//  Adium
//
//  Created by Stephen Holt on Fri Apr 16 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@class SHLinkEditorWindowController, SHLinkFavoritesPreferences;
@protocol AIContentFilter;


@interface SHLinkManagementPlugin : AIPlugin {
    NSToolbarItem   *toolbarItem;
}

@end
