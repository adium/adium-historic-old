//
//  CSSingleWindowInterfacePlugin.h
//  Adium XCode
//
//  Created by Chris Serino on Wed Dec 31 2003.
//

#define HIDE_CONTACT_LIST @"Hide Contact List"
#define SHOW_CONTACT_LIST @"Show Contact List"

@class CSSingleWindowInterfaceWindowController;

@interface CSSingleWindowInterfacePlugin : AIPlugin <AIInterfaceController> {
	CSSingleWindowInterfaceWindowController	   *windowController;
	NSMenuItem                                 *menuItem_showMainWindow;
	NSMenuItem								   *menuItem_collapseContactList;
	NSMenuItem								   *menuItem_close;
}

@end
