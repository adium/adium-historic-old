//
//  AITextProfileWindowController.h
//  Adium
//
//  Created by Adam Iser on Tue Jun 10 2003.
//

@protocol AIListObjectObserver;

@interface AIInfoWindowController : AIWindowController <AIListObjectObserver> {
    IBOutlet	NSTextView	*textView_contactProfile;

    NSTimer             	*timer;
}

+ (id)showInfoWindowForListObject:(AIListObject *)listObject;
+ (void)closeTextProfileWindow;
- (IBAction)closeWindow:(id)sender;
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)configureWindow;

@end
