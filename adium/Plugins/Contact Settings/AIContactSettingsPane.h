//
//  AIContactSettingsPane.h
//  Adium
//
//  Created by Adam Iser on Thu Jun 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIContactSettingsPane : AIContactInfoPane {
	IBOutlet	ESDelayedTextField		*textField_alias;
	
	AIListObject		*listObject;
}

- (IBAction)setAlias:(id)sender;

@end
