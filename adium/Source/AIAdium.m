/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIAdium.h"
#import "AILoginController.h"
#import "AISoundController.h"
#import "AIAccountController.h"
#import "AIToolbarController.h"
#import "AIInterfaceController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIPluginController.h"
#import "AIPreferenceController.h"
#import "AIPreferenceViewController.h"
#import "AIContactInfoViewController.h"
#import "AIMenuController.h"
#import <AIUtilities/AIUtilities.h>

#define ADIUM_DEFAULT_PREFS 			@"Default Preferences"				//File name of Adium's default preferences
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"	//Path to Adium's application support preferences

@interface AIAdium (PRIVATE)
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)completeLogin;
@end

@implementation AIAdium

//Returns the location of Adium's preference folder (within the system's 'application support' directory)
+ (NSString *)applicationSupportDirectory
{
    return([ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]);
}

- (AILoginController *)loginController{
    return(loginController);
}

- (AIMenuController *)menuController{
    return(menuController);
}

- (AIAccountController *)accountController{
    return(accountController);
}

- (AIContentController *)contentController{
    return(contentController);
}

- (AIContactController *)contactController{
    return(contactController);
}

- (AISoundController *)soundController{
    return(soundController);
}

- (AIInterfaceController *)interfaceController{
    return(interfaceController);
}

- (AIPreferenceController *)preferenceController{
    return(preferenceController);
}

- (AIToolbarController *)toolbarController{
    return(toolbarController);
}

// Internal --------------------------------------------------------------------------------

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    //play a sound to prevent a delay later when quicktime loads
//    [AISoundController playSoundNamed:@"Beep"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    //Load an init the components
    [loginController initController];

    //Begin Login
    [loginController requestUserNotifyingTarget:self selector:@selector(completeLogin)];
}

// Called by the login controller when a user has been selected
- (void)completeLogin
{
    //Init the controllers.
    [toolbarController initController];
    [preferenceController initController]; //must init after toolbar controller
    [menuController initController];
    [soundController initController];
    [accountController initController];
    [contactController initController];
    [contentController initController];
    [interfaceController initController];
    [pluginController initController]; //should always load last.  Plugins rely on all the controllers.

    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:ADIUM_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];

    //load the interface
    //The interface depends upon the plugins, so it must load after them
    [interfaceController loadDualInterface];

    //Broadcast a finished launching notification
    [[NSNotificationCenter defaultCenter] postNotificationName:Adium_LaunchComplete object:nil];

    
}

@end

