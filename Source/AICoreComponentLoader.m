/* 
 Adium, Copyright 2001-2004, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/*
 Core - Component Loader

 Loads integrated plugins.  All integrated plugins require a _loadComponentClass statement below and their class name
 in the @class list.  In situations where the load order of plugins is important, please make note.

 */

#import "AICoreComponentLoader.h"

@class 	
AIAccountListPreferencesPlugin,
AIAccountMenuAccessPlugin,
AIAliasSupportPlugin,
AIAlphabeticalSortPlugin,
AIAutoLinkingPlugin,
AIAwayMessagesPlugin,
AIAwayStatusWindowPlugin,
AIChatConsolidationPlugin,
AIChatCyclingPlugin,
AIContactAccountsPlugin,
AIContactAwayPlugin,
AIContactIdlePlugin,
AIContactListEditorPlugin,
AIContactOnlineSincePlugin,
AIContactProfilePlugin,
AIContactSettingsPlugin,
AIContactSortSelectionPlugin,
AIContactStatusColoringPlugin,
AIContactStatusDockOverlaysPlugin,
AIContactStatusEventsPlugin,
AIContactWarningLevelPlugin,
AIDefaultFormattingPlugin,
AIDockAccountStatusPlugin,
AIDockBehaviorPlugin,
AIDockIconSelectionPlugin,
AIDockUnviewedContentPlugin,
AIDualWindowInterfacePlugin,
AIEmoticonsPlugin,
AIEventSoundsPlugin,
AIExtendedStatusPlugin,
AIIdleTimePlugin,
AILoggerPlugin,	
AIManualSortPlugin,
AIMessageAliasPlugin,
AINewMessagePanelPlugin,
AIOfflineContactHidingPlugin,
AISCLViewPlugin,
AISendingKeyPreferencesPlugin,
AIServiceIconPreferencesPlugin,
AISpellCheckingPlugin,
AIStandardToolbarItemsPlugin,
AIStatusChangedMessagesPlugin,
AITabStatusIconsPlugin,
AITextForcingPlugin,
AITextToolbarItemsPlugin,
AITypingNotificationPlugin,
AIVolumeControlPlugin,
BGContactNotesPlugin,
BGEmoticonMenuPlugin,
CBActionSupportPlugin,
CBContactCountingDisplayPlugin,
CBStatusMenuItemPlugin,
CBURLHandlingPlugin,
CPFVersionChecker,
CSDisconnectAllPlugin,
DCInviteToChatPlugin,
DCJoinChatPanelPlugin,
DCMessageContextDisplayPlugin,
ESAccountEvents,
ESAccountNetworkConnectivityPlugin,
ESAddressBookIntegrationPlugin,
ESAnnouncerPlugin,
ESApplescriptContactAlertPlugin,
ESBlockingPlugin,
ESContactAlertsPlugin,
ESContactClientPlugin,
ESContactListWindowHandlingPlugin,
ESContactServersideDisplayName,
ESFastUserSwitchingSupportPlugin,
ESFileTransferMessagesPlugin,
ESMessageEvents,
ESMetaContactContentsPlugin,
ESOpenMessageWindowContactAlertPlugin,
ESSafariLinkToolbarItemPlugin,
ESSendMessageContactAlertPlugin,
ESStatusSortPlugin,
ESUserIconHandlingPlugin,
ErrorMessageHandlerPlugin,
GBApplescriptFiltersPlugin,
IdleMessagePlugin,
JSCEventBezelPlugin,
SAContactOnlineForPlugin,
SHBookmarksImporterPlugin,
SHLinkManagementPlugin;

@interface AICoreComponentLoader (PRIVATE)
- (void)_loadComponentClass:(Class)inClass;
@end

@implementation AICoreComponentLoader

//Load integrated components
- (void)initController
{
	components = [[NSMutableArray alloc] init];
	
	[self _loadComponentClass:[AIAccountListPreferencesPlugin class]];
	[self _loadComponentClass:[AIAccountMenuAccessPlugin class]];
	[self _loadComponentClass:[AIAliasSupportPlugin class]];
	[self _loadComponentClass:[AIAlphabeticalSortPlugin class]];
	[self _loadComponentClass:[AIAutoLinkingPlugin class]];
	[self _loadComponentClass:[AIAwayMessagesPlugin class]];
	[self _loadComponentClass:[AIAwayStatusWindowPlugin class]];
	[self _loadComponentClass:[AIChatConsolidationPlugin class]];
	[self _loadComponentClass:[AIChatCyclingPlugin class]];
	[self _loadComponentClass:[AIContactAccountsPlugin class]];
	[self _loadComponentClass:[AIContactAwayPlugin class]];
	[self _loadComponentClass:[AIContactIdlePlugin class]];
	[self _loadComponentClass:[AIContactListEditorPlugin class]];
	[self _loadComponentClass:[AIContactOnlineSincePlugin class]];
	[self _loadComponentClass:[AIContactProfilePlugin class]];
	[self _loadComponentClass:[AIContactSettingsPlugin class]];
	[self _loadComponentClass:[AIContactSortSelectionPlugin class]];
	[self _loadComponentClass:[AIContactStatusColoringPlugin class]];
	[self _loadComponentClass:[AIContactStatusDockOverlaysPlugin class]];
	[self _loadComponentClass:[AIContactStatusEventsPlugin class]];
	[self _loadComponentClass:[AIContactWarningLevelPlugin class]];
	[self _loadComponentClass:[AIDefaultFormattingPlugin class]];
	[self _loadComponentClass:[AIDockAccountStatusPlugin class]];
	[self _loadComponentClass:[AIDockBehaviorPlugin class]];
	[self _loadComponentClass:[AIDockIconSelectionPlugin class]];
	[self _loadComponentClass:[AIDockUnviewedContentPlugin class]];
	[self _loadComponentClass:[AIDualWindowInterfacePlugin class]];
	[self _loadComponentClass:[AIEmoticonsPlugin class]];
	[self _loadComponentClass:[AIEventSoundsPlugin class]];
	[self _loadComponentClass:[AIExtendedStatusPlugin class]];
	[self _loadComponentClass:[AIIdleTimePlugin class]];
	[self _loadComponentClass:[AILoggerPlugin class]];	
	[self _loadComponentClass:[AIManualSortPlugin class]];
	[self _loadComponentClass:[AIMessageAliasPlugin class]];
	[self _loadComponentClass:[AINewMessagePanelPlugin class]];
	[self _loadComponentClass:[AIOfflineContactHidingPlugin class]];
	[self _loadComponentClass:[AISCLViewPlugin class]];
	[self _loadComponentClass:[AISendingKeyPreferencesPlugin class]];
	[self _loadComponentClass:[AIServiceIconPreferencesPlugin class]];
	[self _loadComponentClass:[AISpellCheckingPlugin class]];
	[self _loadComponentClass:[AIStandardToolbarItemsPlugin class]];
	[self _loadComponentClass:[AIStatusChangedMessagesPlugin class]];
	[self _loadComponentClass:[AITabStatusIconsPlugin class]];
	[self _loadComponentClass:[AITextForcingPlugin class]];
	[self _loadComponentClass:[AITextToolbarItemsPlugin class]];
	[self _loadComponentClass:[AITypingNotificationPlugin class]];
	[self _loadComponentClass:[AIVolumeControlPlugin class]];
	[self _loadComponentClass:[BGContactNotesPlugin class]];
	[self _loadComponentClass:[BGEmoticonMenuPlugin class]];
	[self _loadComponentClass:[CBActionSupportPlugin class]];
	[self _loadComponentClass:[CBContactCountingDisplayPlugin class]];
	[self _loadComponentClass:[CBStatusMenuItemPlugin class]];
	[self _loadComponentClass:[CBURLHandlingPlugin class]];
	[self _loadComponentClass:[CPFVersionChecker class]];
	[self _loadComponentClass:[CSDisconnectAllPlugin class]];
	[self _loadComponentClass:[DCInviteToChatPlugin class]];
	[self _loadComponentClass:[DCJoinChatPanelPlugin class]];
	[self _loadComponentClass:[DCMessageContextDisplayPlugin class]];
	[self _loadComponentClass:[ESAccountEvents class]];
	[self _loadComponentClass:[ESAccountNetworkConnectivityPlugin class]];
	[self _loadComponentClass:[ESAddressBookIntegrationPlugin class]];
	[self _loadComponentClass:[ESAnnouncerPlugin class]];
	[self _loadComponentClass:[ESApplescriptContactAlertPlugin class]];
	[self _loadComponentClass:[ESBlockingPlugin class]];
	[self _loadComponentClass:[ESContactAlertsPlugin class]];
	[self _loadComponentClass:[ESContactClientPlugin class]];
	[self _loadComponentClass:[ESContactListWindowHandlingPlugin class]];
	[self _loadComponentClass:[ESContactServersideDisplayName class]];
	[self _loadComponentClass:[ESFastUserSwitchingSupportPlugin class]];
	[self _loadComponentClass:[ESFileTransferMessagesPlugin class]];
	[self _loadComponentClass:[ESMessageEvents class]];
	[self _loadComponentClass:[ESMetaContactContentsPlugin class]];
	[self _loadComponentClass:[ESOpenMessageWindowContactAlertPlugin class]];
	[self _loadComponentClass:[ESSafariLinkToolbarItemPlugin class]];
	[self _loadComponentClass:[ESSendMessageContactAlertPlugin class]];
	[self _loadComponentClass:[ESStatusSortPlugin class]];
	[self _loadComponentClass:[ESUserIconHandlingPlugin class]];
	[self _loadComponentClass:[ErrorMessageHandlerPlugin class]];
	[self _loadComponentClass:[GBApplescriptFiltersPlugin class]];
	[self _loadComponentClass:[IdleMessagePlugin class]];
	[self _loadComponentClass:[JSCEventBezelPlugin class]];
	[self _loadComponentClass:[SAContactOnlineForPlugin class]];
	[self _loadComponentClass:[SHBookmarksImporterPlugin class]];
	[self _loadComponentClass:[SHLinkManagementPlugin class]];
}

//Give all components a chance to close
- (void)closeController
{
	NSEnumerator	*enumerator = [components objectEnumerator];
	AIPlugin		*plugin;
		
	while(plugin = [enumerator nextObject]){
		[plugin uninstallPlugin];
	}
	
	[components release];
	components = nil;
}

//Load an integrated component plugin
- (void)_loadComponentClass:(Class)inClass
{
	id object;

	if(object = [inClass newInstanceOfPlugin]){
		[components addObject:object];
	}else{
		NSString	*error = [NSString stringWithFormat:@"Failed to load %@",NSStringFromClass(inClass)];
		NSAssert(object, error);
	}
}

@end
