//
//  AIContactInfoPlugin.h
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//

@protocol AIMiniToolbarItemDelegate;

@interface AIContactInfoPlugin : AIPlugin <AIMiniToolbarItemDelegate> {
    NSMenuItem				*viewContactInfoMenuItem;
    NSMenuItem				*viewContactInfoMenuItem_alternate;
    NSMenuItem				*getInfoContextMenuItem;
}

@end
