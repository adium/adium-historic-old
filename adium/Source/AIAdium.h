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

#import "AIAccountController.h"
#import "ESContactAlertsController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIDockController.h"
#import "ESFileTransferController.h"
#import "AIInterfaceController.h"
#import "AILoginController.h"
#import "AIMenuController.h"
#import "AIPluginController.h"
#import "AIPreferenceController.h"
#import "AISoundController.h"
#import "AIToolbarController.h"

@class AISortController, AILoginController, AIAccountController, AIInterfaceController, AIContactController, AIPluginController, AIPreferenceController, AIPreferencePane, AIMenuController, AILoginWindowController, AIAccountWindowController, AIAccount, AIMessageObject, AIServiceType, AIPreferenceCategory, AIContactInfoView, AIMiniToolbar, AIAnimatedView, AIContentController, AIToolbarController, AIContactInfoViewController, AIPreferenceViewController, AISoundController, AIDockController, AIHandle, AIListContact, AIListGroup, AIListObject, AIIconState, AIContactListGeneration, AIChat, AIContentObject, ESFileTransferController, ESFileTransfer, ESContactAlertsController, ESContactAlert, AIMutableOwnerArray;
@class SUSpeaker;

@interface AIAdium : NSObject {
    IBOutlet	AIMenuController            *menuController;
    IBOutlet	AILoginController           *loginController;
    IBOutlet	AIAccountController         *accountController;
    IBOutlet	AIInterfaceController       *interfaceController;
    IBOutlet	AIContactController         *contactController;
    IBOutlet	AIContentController         *contentController;
    IBOutlet	AIPluginController          *pluginController;
    IBOutlet	AIPreferenceController      *preferenceController;
    IBOutlet	AIToolbarController         *toolbarController;
    IBOutlet	AISoundController           *soundController;
    IBOutlet	AIDockController            *dockController;
    IBOutlet    ESFileTransferController    *fileTransferController;
    IBOutlet    ESContactAlertsController   *contactAlertsController;
    
    NSNotificationCenter                    *notificationCenter;
    NSMutableDictionary                     *eventNotifications;
    
    BOOL                                    completedApplicationLoad;
}

+ (NSString *)applicationSupportDirectory;
- (AILoginController *)loginController;
- (AIAccountController *)accountController;
- (AIContactController *)contactController;
- (AIContentController *)contentController;
- (AIToolbarController *)toolbarController;
- (AISoundController *)soundController;
- (AIInterfaceController *)interfaceController;
- (AIPreferenceController *)preferenceController;
- (AIMenuController *)menuController;
- (AIDockController *)dockController;
- (ESFileTransferController *)fileTransferController;
- (ESContactAlertsController *)contactAlertsController;

- (NSNotificationCenter *)notificationCenter;
- (void)registerEventNotification:(NSString *)inNotification displayName:(NSString *)displayName;
- (NSDictionary *)eventNotifications;

- (IBAction)showAboutBox:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)confirmQuit:(id)sender;

@end

//Crash Reporter
#define PATH_TO_CRASH_REPORTER  [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/Adium Crash Reporter.app"] stringByExpandingTildeInPath]
#define EXCEPTIONS_PATH		[@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]
#define CRASHES_PATH		[@"~/Library/Logs/CrashReporter/Adium.crash.log" stringByExpandingTildeInPath]

//Localization
#define AILocalizedString(key, comment) [[NSBundle bundleForClass: [self class]] localizedStringForKey: (key) value:@"" table:nil]

//Adium events
#define KEY_EVENT_DISPLAY_NAME		@"DisplayName"
#define KEY_EVENT_NOTIFICATION		@"Notification"

//Adium Notifications
#define CONTACT_STATUS_ONLINE_YES                               @"Contact_StatusOnlineYes"
#define CONTACT_STATUS_ONLINE_NO                                @"Contact_StatusOnlineNO"
#define CONTACT_STATUS_AWAY_YES                                 @"Contact_StatusAwayYes"
#define CONTACT_STATUS_AWAY_NO                                  @"Contact_StatusAwayNo"
#define CONTACT_STATUS_IDLE_YES                                 @"Contact_StatusIdleYes"
#define CONTACT_STATUS_IDLE_NO                                  @"Contact_StatusIdleNo"

