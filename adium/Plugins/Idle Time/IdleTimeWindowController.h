/* IdleTimeWindowController */

#import <Cocoa/Cocoa.h>
#import "IdleTimePlugin.h"

@class AIAccountController;

@interface IdleTimeWindowController : NSWindowController
{
    IBOutlet 	NSPopUpButton 	*accountPopup;
    IBOutlet	NSTextField	*text_SetIdleDays;
    IBOutlet	NSTextField	*text_SetIdleHours;
    IBOutlet	NSTextField	*text_SetIdleMinutes;
    AIAdium	*owner;
}
+ (id)IdleTimeWindowControllerWithOwner:(id)inOwner;
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)buildAccountsPopup;
- (IBAction)setIdle:(id)sender;
- (IBAction)unIdle:(id)sender;
- (IBAction)cancel:(id)sender;
@end
