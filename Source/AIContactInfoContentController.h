//
//  AIContactInfoContentController.h
//  Adium
//
//  Created by Elliott Harris on 1/13/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/ABPeoplePickerView.h>

@interface AIContactInfoContentController : NSObject {
	NSObjectController				*listObjectController;
	
	IBOutlet NSSegmentedControl		*inspectorToolbar;
	IBOutlet NSPanel				*infoInspector;
	IBOutlet NSView					*panelContent;
	
	IBOutlet id						currentView;
	IBOutlet NSView					*infoView;
	IBOutlet NSView					*addressBookView;
	IBOutlet NSView					*eventsView;
	IBOutlet NSView					*advancedView;
	
	IBOutlet NSPanel				*addressBookPanel;
	IBOutlet NSView					*addressBookPalette;
	IBOutlet ABPeoplePickerView		*addressBookPicker;
}

//Segmented Control action
-(IBAction)segmentSelected:(id)sender;

//Address Book Panel actions
-(IBAction)runABPanel:(id)sender;
-(IBAction)cardSelected:(id)sender;
-(IBAction)cancelABPanel:(id)sender;




@end
