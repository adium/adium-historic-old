//
//  BGThemesPreferences.h
//  Adium XCode
//
//  Created by Brian Ganninger on Sat Jan 03 2004.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "BGThemeManageView.h"

@interface BGThemesPreferences : AIPreferencePane {
    // create tab
    IBOutlet NSWindow *createWindow;
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *authorField;
    IBOutlet NSTextField *versionField;
    IBOutlet AIPlasticButton *createButton;
    IBOutlet AIPlasticButton *removeButton;
    // manage tab
    IBOutlet BGThemeManageView *themesList;
    // other
    id themePlugin;
    NSMenu *themeMenu;
}
-(IBAction)createAction:(id)sender;
-(IBAction)createTheme:(id)sender;
-(void)setPlugin:(id)newPlugin;
-(void)createDone;
@end
