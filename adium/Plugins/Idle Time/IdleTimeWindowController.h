/* IdleTimeWindowController */

#import <Cocoa/Cocoa.h>
#import "IdleTimePlugin.h"

@class AIAccountController, AIIdleTimePlugin;

@interface IdleTimeWindowController : NSWindowController
{
    AIIdleTimePlugin	*owner;

    IBOutlet 	NSPopUpButton 	*popUp_Accounts;
    IBOutlet	NSButton	*checkBox_SetManually;
    IBOutlet	NSTextField	*textField_IdleDays;
    IBOutlet	NSTextField	*textField_IdleHours;
    IBOutlet	NSTextField	*textField_IdleMinutes;
    IBOutlet	NSStepper	*stepper_IdleDays;
    IBOutlet	NSStepper	*stepper_IdleHours;
    IBOutlet	NSStepper	*stepper_IdleMinutes;
    IBOutlet	NSButton	*button_Apply;
}

+ (id)idleTimeWindowControllerWithOwner:(id)inOwner;
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (IBAction)apply:(id)sender;
- (IBAction)configureControls:(id)sender;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (BOOL)windowShouldClose:(id)sender;

@end
