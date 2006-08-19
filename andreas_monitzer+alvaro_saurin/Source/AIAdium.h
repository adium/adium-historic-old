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

@class  AICorePluginLoader, AICoreComponentLoader, SUUpdater;

@protocol	AIAccountController, AIChatController, AIContactAlertsController, AIDebugController,
			AIPreferenceController, AIMenuController, AIApplescriptabilityController, AIStatusController,
			AIContentController, AIToolbarController, AISoundController, AIDockController,
			AIFileTransferController, AILoginController, AIInterfaceController, AIContactController,
			AIEmoticonController, AIJavaController, AIVideoConfController;

@interface AIAdium : NSObject {
    IBOutlet	NSObject <AIMenuController>			*menuController;
    IBOutlet	NSObject <AIInterfaceController>		*interfaceController;
	IBOutlet	SUUpdater						*updater;

	NSObject <AIAccountController>		*accountController;
	NSObject <AIChatController>			*chatController;
	NSObject <AIContactController>		*contactController;
	NSObject <AIContentController>		*contentController;
	NSObject <AIDockController>			*dockController;
	NSObject <AIEmoticonController>		*emoticonController;
	NSObject <AILoginController>		*loginController;
	NSObject <AIPreferenceController>	*preferenceController;
	NSObject <AISoundController>		*soundController;
	NSObject <AIStatusController>		*statusController;
	NSObject <AIToolbarController>		*toolbarController;
	NSObject <AIContactAlertsController>*contactAlertsController;
	NSObject <AIFileTransferController>	*fileTransferController;
    NSObject <AIJavaController>         *javaController;
	NSObject <AIVideoConfController>	*vcController;

	NSObject <AIApplescriptabilityController>	*applescriptabilityController;
	NSObject <AIDebugController>				*debugController;

	
	AICoreComponentLoader			*componentLoader;
	AICorePluginLoader				*pluginLoader;
    
    NSNotificationCenter			*notificationCenter;
    NSMutableDictionary				*eventNotifications;

	//pathnames to the different Application Support folders.
    NSArray							*appSupportPaths;
	
	NSMutableArray					*queuedURLEvents;
	NSString						*queuedLogPathToShow;
    BOOL							completedApplicationLoad;
	NSString						*advancedPrefsName;	
}

+ (NSString *)buildIdentifier;
+ (NSDate *)buildDate;

- (NSObject <AIAccountController> *)accountController;
- (NSObject <AIChatController> *)chatController;
- (NSObject <AIContactController> *)contactController;
- (NSObject <AIContentController> *)contentController;
- (NSObject <AIDockController> *)dockController;
- (NSObject <AIEmoticonController> *)emoticonController;
- (NSObject <AIInterfaceController> *)interfaceController;
- (NSObject <AILoginController> *)loginController;
- (NSObject <AIMenuController> *)menuController;
- (NSObject <AIPreferenceController> *)preferenceController;
- (NSObject <AISoundController> *)soundController;
- (NSObject <AIStatusController> *)statusController;
- (NSObject <AIToolbarController> *)toolbarController;
- (NSObject <AIContactAlertsController> *)contactAlertsController;
- (NSObject <AIFileTransferController> *)fileTransferController;
- (NSObject <AIJavaController> *)javaController;
- (NSObject <AIVideoConfController> *)vcController;

- (NSObject <AIDebugController> *)debugController;
- (NSObject <AIApplescriptabilityController> *)applescriptabilityController;

- (AICoreComponentLoader *)componentLoader;

- (NSNotificationCenter *)notificationCenter;

- (IBAction)showAboutBox:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)reportABug:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)showForums:(id)sender;
- (IBAction)showXtras:(id)sender;
- (IBAction)confirmQuit:(id)sender;
- (IBAction)contibutingToAdium:(id)sender;
- (IBAction)donate:(id)sender;

- (NSString *)applicationSupportDirectory;
- (NSString *)createResourcePathForName:(NSString *)name;
- (NSArray *)resourcePathsForName:(NSString *)name;
- (NSArray *)allResourcesForName:(NSString *)name withExtensions:(id)extensions;
- (NSString *)pathOfPackWithName:(NSString *)name extension:(NSString *)extension resourceFolderName:(NSString *)folderName;
- (NSString *)cachesPath;

@end

//Adium events
#define KEY_EVENT_DISPLAY_NAME		@"DisplayName"
#define KEY_EVENT_NOTIFICATION		@"Notification"

//Adium Notifications
#define CONTACT_STATUS_ONLINE_YES			@"Contact_StatusOnlineYes"	// Contact signs on
#define CONTACT_STATUS_ONLINE_NO			@"Contact_StatusOnlineNo"	// Contact signs off
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
#define CONTENT_CONTACT_JOINED_CHAT			@"Content_ContactJoinedChat"
#define CONTENT_CONTACT_LEFT_CHAT			@"Content_ContactLeftChat"
#define INTERFACE_ERROR_MESSAGE				@"Interface_ErrorMessageReceived"
#define ACCOUNT_CONNECTED					@"Account_Connected"
#define ACCOUNT_DISCONNECTED				@"Account_Disconnected"
#define	ACCOUNT_RECEIVED_EMAIL				@"Account_NewMailReceived"
#define FILE_TRANSFER_REQUEST				@"FileTransfer_Request"
#define FILE_TRANSFER_CHECKSUMMING			@"FileTransfer_Checksumming"
#define FILE_TRANSFER_BEGAN					@"FileTransfer_Began"
#define FILE_TRANSFER_CANCELLED				@"FileTransfer_Cancelled"
#define FILE_TRANSFER_FAILED				@"FileTransfer_Failed"
#define FILE_TRANSFER_COMPLETE				@"FileTransfer_Complete"

#define Adium_Xtras_Changed					@"Adium_Xtras_Changed"
#define Adium_CompletedApplicationLoad		@"Adium_CompletedApplicationLoad"
#define Adium_WillTerminate					@"Adium_WillTerminate"
#define Adium_ShowLogAtPath					@"Adium_ShowLogAtPath"
