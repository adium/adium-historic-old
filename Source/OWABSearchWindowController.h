//
//  OWABSearchWindowController.h
//  Adium
//
//  Created by Ofri Wolfus on 19/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <Adium/AIWindowController.h>

@class AILocalizationButton, ABPeoplePickerView, AIService, ABPerson;

@interface OWABSearchWindowController : AIWindowController {
	IBOutlet ABPeoplePickerView		*peoplePicker;
	
	IBOutlet AILocalizationButton	*selectButton;
	IBOutlet AILocalizationButton	*cancelButton;
	IBOutlet AILocalizationButton	*newPersonButton;
	
	id	delegate;
}

+ (id)promptForNewPersonSearchOnWindow:(NSWindow *)parentWindow;
- (IBAction)select:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)createNewPerson:(id)sender;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (ABPerson *)selectedPerson;
- (NSString *)selectedScreenName;
- (NSString *)selectedName;
- (NSString *)selectedAlias;
- (AIService *)selectedService;

@end

//Delegate Methods
@interface NSObject (OWABSearchWindowControllerDelegate)
- (void)absearchWindowControllerDidSelectPerson:(OWABSearchWindowController *)controller;
@end

//Notifications
#define OWABSearchWindowControllerDidSelectPersonNotification	@"OWABSearchWindowControllerDidSelectPerson"
