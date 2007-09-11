/* AINewBookmarkWindowController */

#import <Cocoa/Cocoa.h>
#import <AIWindowController.h>
#import <Adium/AIContactControllerProtocol.h>

@interface AINewBookmarkWindowController : AIWindowController
{
    IBOutlet id myOutlet;
    IBOutlet id popUp_group;
    IBOutlet id textField_name;
			 id delegate;
}
+(AINewBookmarkWindowController *)promptForNewBookmarkOnWindow:(NSWindow*)parentWindow;
- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;
-(void)setDelegate:(id)newDelegate;
-(id)delegate;
- (void)buildGroupMenu;

@end
