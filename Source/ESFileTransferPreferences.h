//
//  ESFileTransferPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 11/27/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ESFileTransferPreferences : AIPreferencePane {
	IBOutlet	NSPopUpButton	*popUp_downloadLocation;
	IBOutlet	NSButton		*checkBox_autoAcceptFiles;
	IBOutlet	NSButton		*checkBox_autoAcceptOnlyFromCLList;

	IBOutlet	NSButton		*checkBox_autoOpenFiles;
	IBOutlet	NSButton		*checkBox_showProgress;
}

@end
