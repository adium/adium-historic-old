//
//  SHLinkManagementPlugin.h
//  Adium
//
//  Created by Stephen Holt on Fri Apr 16 2004.

@class SHLinkEditorWindowController, SHLinkFavoritesPreferences;
@protocol AIContentFilter;


@interface SHLinkManagementPlugin : AIPlugin {

    NSMenuItem                          *menu_AddLink;
    NSMenuItem                          *menu_EditLink;
        
    SHLinkEditorWindowController        *editorWindow;
    SHLinkFavoritesPreferences          *preferences;

}

@end
