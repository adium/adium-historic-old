//
//  AIAliasSupportPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Adium/Adium.h>

@protocol AIListEditorColumnController;

@interface AIAliasSupportPlugin : AIPlugin <AIPreferenceViewControllerDelegate, AIContactObserver, AIListEditorColumnController> {
    IBOutlet    NSView		*view_contactAliasInfoView;
    IBOutlet	NSTextField	*textField_alias;

    AIPreferenceViewController		*contactView;
    AIListContact			*activeContactObject;
}

- (void)installPlugin;
- (IBAction)setAlias:(id)sender;
- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject;

@end
