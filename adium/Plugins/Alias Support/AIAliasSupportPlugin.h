//
//  AIAliasSupportPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Adium/Adium.h>

@interface AIAliasSupportPlugin : AIPlugin <AIPreferenceViewControllerDelegate> {
    IBOutlet    NSView		*view_contactAliasInfoView;
    IBOutlet	NSTextField	*textField_alias;

    AIPreferenceViewController		*contactView;
}

- (IBAction)setAlias:(id)sender;

@end
