/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#define	BETA_RELEASE FALSE

@class  AISortController, AILoginController, AIAccountController, AIInterfaceController, AIContactController, 
		AICorePluginLoader, AIPreferenceController, AIMenuController, AILoginWindowController,
		AICoreComponentLoader, AIContentController, AIToolbarController, AIContactInfoViewController, 
		AIPreferenceViewController, AISoundController, AIDockController, ESFileTransferController, 
		ESContactAlertsController, ESApplescriptabilityController, AIStatusController, ESDebugController;

@interface AIAdium : NSObject {
    IBOutlet	AIAccountController				*accountController;
    IBOutlet	AIContactController				*contactController;
    IBOutlet	AIContentController				*contentController;
    IBOutlet	AIDockController				*dockController;
    IBOutlet	AIInterfaceController			*interfaceController;
    IBOutlet	AILoginController				*loginController;
    IBOutlet	AIMenuController				*menuController;
    IBOutlet	AIPreferenceController			*preferenceController;
    IBOutlet	AISoundController				*soundController;
    IBOutlet	AIStatusController				*statusController;
    IBOutlet	AIToolbarController				*toolbarController;
    IBOutlet	ESApplescriptabilityController	*applescriptabilityController;
    IBOutlet	ESDebugController				*debugController;
    IBOutlet    ESContactAlertsController		*contactAlertsController;
    IBOutlet    ESFileTransferController		*fileTransferController;

	IBOutlet	AICoreComponentLoader			*componentLoader;
	IBOutlet	AICorePluginLoader				*pluginLoader;
    
    NSNotificationCenter						*notificationCenter;
    NSMutableDictionary							*eventNotifications;

	//pathnames to the different Application Support folders.
    NSArray										*appSupportPaths;

    BOOL										completedApplicationLoad;
	NSString									*advancedPrefsName;	
}

+ (NSString *)applicationSupportDirectory;
- (AIAccountController *)accountController;
- (AIContactController *)contactController;
- (AIContentController *)contentController;
- (AIDockController *)dockController;
- (AIInterfaceController *)interfaceController;
- (AILoginController *)loginController;
- (AIMenuController *)menuController;
- (AIPreferenceController *)preferenceController;
- (AISoundController *)soundController;
- (AIStatusController *)statusController;
- (AIToolbarController *)toolbarController;
- (ESContactAlertsController *)contactAlertsController;
- (ESDebugController *)debugController;
- (ESFileTransferController *)fileTransferController;

- (NSNotificationCenter *)notificationCenter;

- (IBAction)showAboutBox:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)reportABug:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)showForums:(id)sender;
- (IBAction)showXtras:(id)sender;
- (IBAction)confirmQuit:(id)sender;
- (IBAction)launchJeeves:(id)sender;

- (NSString *)createResourcePathForName:(NSString *)name;
- (NSArray *)resourcePathsForName:(NSString *)name;
- (NSString *)pathOfPackWithName:(NSString *)name extension:(NSString *)extension resourceFolderName:(NSString *)folderName;
- (NSString *)cachesPath;

@end

//Crash Reporter
#define PATH_TO_IMPORTER              [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/Adium 1.6 Pref Importer.app"] stringByExpandingTildeInPath]
#define EXCEPTIONS_PATH               [@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]
#define CRASHES_PATH                  [@"~/Library/Logs/CrashReporter/Adium.crash.log" stringByExpandingTildeInPath]

//Debugging
#if BETA_RELEASE			/* Automatically turn on DEBUG_BUILD for all BETA_RELEASE builds */
	#ifndef DEBUG_BUILD
		#define DEBUG_BUILD
	#endif
#endif

//Adium events
#define KEY_EVENT_DISPLAY_NAME		@"DisplayName"
#define KEY_EVENT_NOTIFICATION		@"Notification"

//Adium Notifications
#define CONTACT_STATUS_ONLINE_YES			@"Contact_StatusOnlineYes"
#define CONTACT_STATUS_ONLINE_NO			@"Contact_StatusOnlineNo"
#define CONTACT_STATUS_AWAY_YES				@"Contact_StatusAwayYes"
#define CONTACT_STATUS_AWAY_NO				@"Contact_StatusAwayNo"
#define CONTACT_STATUS_IDLE_YES				@"Contact_StatusIdleYes"
#define CONTACT_STATUS_IDLE_NO				@"Contact_StatusIdleNo"
#define CONTACT_STATUS_MESSAGE				@"Contact_StatusMessage"
#define CONTACT_SEEN_ONLINE_YES				@"Contact_SeenOnlineYes"
#define CONTACT_SEEN_ONLINE_NO				@"Contact_SeenOnlineNo"
#define CONTENT_MESSAGE_SENT				@"Content_MessageSent"
#define CONTENT_MESSAGE_RECEIVED			@"Content_MessageReceived"
#define CONTENT_MESSAGE_RECEIVED_FIRST		@"Content_MessageReceivedFirst"
#define CONTENT_MESSAGE_RECEIVED_BACKGROUND	@"Content_MessageReceivedBackground"
#define INTERFACE_ERROR_MESSAGE				@"Interface_ErrorMessageReceived"
#define ACCOUNT_CONNECTED					@"Account_Connected"
#define ACCOUNT_DISCONNECTED				@"Account_Disconnected"
#define	ACCOUNT_RECEIVED_EMAIL				@"Account_NewMailReceived"
#define FILE_TRANSFER_REQUEST				@"FileTransfer_Request"
#define FILE_TRANSFER_BEGAN					@"FileTransfer_Began"
#define FILE_TRANSFER_CANCELED				@"FileTransfer_Canceled"
#define FILE_TRANSFER_COMPLETE				@"FileTransfer_Complete"

#define Adium_Xtras_Changed					@"Adium_Xtras_Changed"
#define Adium_CompletedApplicationLoad		@"Adium_CompletedApplicationLoad"
//#define	Adium_VersionWillBeUpgraded		@"Adium_VersionWillBeUpgraded"
//#define	Adium_VersionUpgraded			@"Adium_VersionUpgraded"
