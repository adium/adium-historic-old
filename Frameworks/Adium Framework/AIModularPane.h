//
//  AIModularPane.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//

#import "AIObject.h"

@interface AIModularPane : AIObject {
    IBOutlet    	NSView  		*view;
    id								plugin;
	
}

//
+ (AIModularPane *)modularPane;
+ (AIModularPane *)modularPaneForPlugin:(id)inPlugin;
- (id)initForPlugin:(id)inPlugin;
- (id)init;
- (NSComparisonResult)compare:(AIModularPane *)inPane;
- (NSView *)view;
- (void)closeView;

//For subclasses
- (NSString *)label;
- (NSString *)nibName;
- (void)viewDidLoad;
- (void)viewWillClose;
- (IBAction)changePreference:(id)sender;
- (void)configureControlDimming;
- (BOOL)resizable;


@end
