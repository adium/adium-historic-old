/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIMenuController.h"
#import "AIDockController.h"
#import <AIUtilities/AIUtilities.h>

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

- (AIDockController *)dockController{
    return(dockController);
}

// Notifications --
- (NSNotificationCenter *)notificationCenter
{
    if(notificationCenter == nil){
        notificationCenter = [[NSNotificationCenter alloc] init];
    }

    return(notificationCenter);
}

// Specific notifications can be given a human-readable name and registered as events - which can be used to trigger various actions
- (void)registerEventNotification:(NSString *)inNotification displayName:(NSString *)displayName
{
    [eventNotifications setObject:[NSDictionary dictionaryWithObjectsAndKeys:inNotification, KEY_EVENT_NOTIFICATION, displayName, KEY_EVENT_DISPLAY_NAME, nil] forKey:inNotification];
}

- (NSDictionary *)eventNotifications
{
    return(eventNotifications);
}


// Internal --------------------------------------------------------------------------------

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    //init
    notificationCenter = nil;
    eventNotifications = [[NSMutableDictionary alloc] init];
    
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
    [dockController initController];
    [pluginController initController]; //should always load last.  Plugins rely on all the controllers.

    //
    [interfaceController finishIniting];
    [accountController finishIniting];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    //Close the controllers in reverse order
    [pluginController closeController]; //should always load last.  Plugins rely on all the controllers.
    [dockController initController];
    [interfaceController closeController];
    [contentController closeController];
    [contactController closeController];
    [accountController closeController];
    [soundController closeController];
    [menuController closeController];
    [preferenceController closeController];
    [toolbarController closeController];
}

@end

