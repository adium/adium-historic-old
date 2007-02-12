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

@class  AICorePluginLoader, AICoreComponentLoader, SUUpdater;

@protocol	AIAdium;
@protocol	AIAccountController, AIChatController, AIContactAlertsController, AIDebugController,
			AIPreferenceController, AIMenuController, AIApplescriptabilityController, AIStatusController,
			AIContentController, AIToolbarController, AISoundController, AIDockController,
			AIFileTransferController, AILoginController, AIInterfaceController, AIContactController,
			AIEmoticonController;

@interface AIAdium : NSObject <AIAdium> {
    IBOutlet	NSObject <AIMenuController>			*menuController;
    IBOutlet	NSObject <AIInterfaceController>	*interfaceController;
	IBOutlet	SUUpdater							*updater;

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

- (IBAction)showAboutBox:(id)sender;
- (IBAction)reportABug:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)showForums:(id)sender;
- (IBAction)showXtras:(id)sender;
- (IBAction)confirmQuit:(id)sender;
- (IBAction)contibutingToAdium:(id)sender;
- (IBAction)donate:(id)sender;

@end
