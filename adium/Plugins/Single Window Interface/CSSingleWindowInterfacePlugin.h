//
//  CSSingleWindowInterfacePlugin.h
//  Adium XCode
//
//  Created by Chris Serino on Wed Dec 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@class CSSingleWindowInterfaceWindowController;

@interface CSSingleWindowInterfacePlugin : AIPlugin <AIInterfaceController> {
	CSSingleWindowInterfaceWindowController	   *windowController;
	NSMenuItem                                 *menuItem_showMainWindow;
	NSMenuItem								   *menuItem_close;
}

@end
