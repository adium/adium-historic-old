//
//  ESPanelApplescriptDetailPane.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Sep 08 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface ESPanelApplescriptDetailPane : AIActionDetailsPane {
	IBOutlet	NSTextField		*textField_scriptName;
	NSString					*scriptPath;
}

- (IBAction)chooseFile:(id)sender;

@end
