//
//  ESFileTransferPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 11/27/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ESFileTransferPreferences : AIPreferencePane {
	IBOutlet	NSPopUpButton			*popUp_downloadLocation;
	IBOutlet	AILocalizationButton	*checkBox_autoAcceptFiles;
	IBOutlet	AILocalizationButton	*checkBox_autoAcceptOnlyFromCLList;

	IBOutlet	AILocalizationButton	*checkBox_autoOpenFiles;
	IBOutlet	AILocalizationButton	*checkBox_autoClearCompleted;
	IBOutlet	AILocalizationButton	*checkBox_showProgress;
	
	IBOutlet	AILocalizationTextField	*label_whenReceivingFiles;
	IBOutlet	AILocalizationTextField	*label_defaultReceivingFolder;
	IBOutlet	AILocalizationTextField	*label_safeFilesDescription;
	IBOutlet	AILocalizationTextField	*label_transferProgress;
}

@end
