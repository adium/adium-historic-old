//
//  AIContactInfoPlugin.h
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@protocol AIMiniToolbarItemDelegate;

@interface AIContactInfoPlugin : AIPlugin <AIMiniToolbarItemDelegate> {
    NSMenuItem				*viewContactInfoMenuItem;
    NSMenuItem				*getInfoContextMenuItem;
}

@end
