//
//  BGEmoticonMenuPlugin.h
//  Adium XCode
//
//  Created by Brian Ganninger on Sun Dec 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface BGEmoticonMenuPlugin : AIPlugin
{
    NSArray *emoticons;
    NSMenu *eMenu;
    NSMenuItem *toolbarMenu;
    NSMenuItem *quickMenuItem;
    NSPopUpButton *menuButton;
    NSToolbarItem *toolbarItem;
}
-(NSMenu *)eMenu;
-(void)buildMenu;
-(void)buildContextualMenu;
-(NSToolbarItem *)toolbarItem;
-(void)buildToolbarItem;
@end
