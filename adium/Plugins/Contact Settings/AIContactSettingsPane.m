//
//  AIContactSettingsPane.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactSettingsPane.h"

#define 		PREF_GROUP_ALIASES 			@"Aliases"
#define			PREF_GROUP_NOTES			@"Notes"		//Preference group to store notes in

@implementation AIContactSettingsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Settings);
}
- (NSString *)label{
    return(@"Settings");
}
- (NSString *)nibName{
    return(@"ContactSettingsPane");
}

//Configure the preference view
- (void)viewDidLoad
{

}

//Preference view is closing
- (void)viewWillClose
{
	[listObject release]; listObject = nil;
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	NSString	*note;
	NSString	*alias;

	//Be sure we've set the last changes before changing which object we are editing
	[textField_alias fireImmediately];
	
	//Hold onto the object
	[listObject release];
	listObject = [inObject retain];
	
	//Fill in the current alias
	if(alias = [inObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES]){
		[textField_alias setStringValue:alias];
	}else{
		[textField_alias setStringValue:@""];
	}
	
	//Current note
    if(note = [inObject preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES]){
        [textField_notes setStringValue:note];
    }else{
        [textField_notes setStringValue:@""];
    }
}

//Apply an alias
- (IBAction)setAlias:(id)sender
{
    if(listObject){
        NSString	*alias = [textField_alias stringValue];
        if([alias length] == 0) alias = nil; 
        
        //Apply
//        [self _applyAlias:alias toObject:activeListObject notify:YES];
        
        //Save the alias
        [listObject setPreference:alias forKey:@"Alias" group:PREF_GROUP_ALIASES];
    }
}

//Save contact notes
- (IBAction)setNotes:(id)sender
{
    if(listObject){
        NSString 	*notes = [textField_notes stringValue];
        if([notes length] == 0) notes = nil; 

		//Save the note
        [listObject setPreference:notes forKey:@"Notes" group:PREF_GROUP_NOTES];
    }
}

@end
