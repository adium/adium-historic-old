//
//  BGThemesPreferences.h
//  Adium XCode
//
//  Created by Brian Ganninger on Sat Jan 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "BGThemeManageView.h"

@interface BGThemesPreferences : AIPreferencePane {
    // create tab
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *authorField;
    IBOutlet NSTextField *versionField;
    IBOutlet NSButton *createButton;
    IBOutlet NSTextField *createStatus;
    // manage tab
    IBOutlet BGThemeManageView *themesList;
    IBOutlet NSImageView *applyPreview;
    IBOutlet NSTextField *manageStatus;
    // other
    IBOutlet NSButton *themesFolderButton;
    id themePlugin;
    NSMenu *themeMenu;
}
-(IBAction)createTheme:(id)sender;
-(IBAction)openThemesFolder:(id)sender;
-(void)setPlugin:(id)newPlugin;
-(void)applyDone;
-(void)createDone;
@end
