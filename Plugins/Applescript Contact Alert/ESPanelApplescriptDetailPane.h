//
//  ESPanelApplescriptDetailPane.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Sep 08 2004.

@interface ESPanelApplescriptDetailPane : AIActionDetailsPane {
	IBOutlet	NSTextField		*textField_scriptName;
	NSString					*scriptPath;
}

- (IBAction)chooseFile:(id)sender;

@end
