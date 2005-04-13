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

/*!
 * @class AICoreComponentLoader
 * @brief Core - Component Loader

 * Loads integrated plugins.  All integrated plugins require a _loadComponentClass statement below and their class name
 * in the @class list.  In situations where the load order of plugins is important, please make note.
 */

#import "AICoreComponentLoader.h"
#import <Adium/AIPlugin.h>

/* Source */
#import "AIAccountListPreferencesPlugin.h"
#import "AIAccountMenuAccessPlugin.h"
#import "AIAliasSupportPlugin.h"
#import "AIAppearancePreferencesPlugin.h"
#import "AIAutoIdlePlugin.h"
#import "AIAutoLinkingPlugin.h"
#import "AIAutoReplyPlugin.h"
#import "AIChatConsolidationPlugin.h"
#import "AIChatCyclingPlugin.h"
#import "AIContactAwayPlugin.h"
#import "AIContactIdlePlugin.h"
#import "AIContactListEditorPlugin.h"
#import "AIContactOnlineSincePlugin.h"
#import "AIContactSortSelectionPlugin.h"
#import "AIContactStatusEventsPlugin.h"
#import "AIContactWarningLevelPlugin.h"
#import "AIDefaultFormattingPlugin.h"
#import "AIDockAccountStatusPlugin.h"
#import "AIDockBehaviorPlugin.h"
#import "AIEventSoundsPlugin.h"
#import "AIExtendedStatusPlugin.h"
#import "AINewMessagePanelPlugin.h"
#import "AIOfflineContactHidingPlugin.h"
#import "AIStandardToolbarItemsPlugin.h"
#import "AIStateMenuPlugin.h"
#import "AIStatusChangedMessagesPlugin.h"
#import "AITabStatusIconsPlugin.h"
#import "AITypingNotificationPlugin.h"
#import "BGContactNotesPlugin.h"
#import "CBActionSupportPlugin.h"
#import "CBContactCountingDisplayPlugin.h"
#import "CBContactLastSeenPlugin.h"
#import "CPFVersionChecker.h"
#import "GBApplescriptFiltersPlugin.h"
#import "NEHGrowlPlugin.h"
#import "SAContactOnlineForPlugin.h"
#import "ESAccountEvents.h"
#import "ESAccountNetworkConnectivityPlugin.h"
#import "ESAddressBookIntegrationPlugin.h"
#import "ESAnnouncerPlugin.h"
#import "ESApplescriptContactAlertPlugin.h"
#import "ESAutoAwayPlugin.h"
#import "ESAwayStatusWindowPlugin.h"
#import "ESBlockingPlugin.h"
#import "ESContactClientPlugin.h"
#import "ESContactServersideDisplayName.h"
#import "ESFastUserSwitchingSupportPlugin.h"
#import "ESMetaContactContentsPlugin.h"
#import "ESStatusPreferencesPlugin.h"
#import "ESUserIconHandlingPlugin.h"

/* Plugins/Contact List */
#import "AISCLViewPlugin.h"

/* Plugins/Contact Status Coloring */
#import "AIContactStatusColoringPlugin.h"

/* Plugins/Contact Status Dock Overlays */
#import "AIContactStatusDockOverlaysPlugin.h"

/* Plugins/Dock Unviewed Content */
#import "AIDockUnviewedContentPlugin.h"

/* Plugins/Dual Window Interface */
#import "AIDualWindowInterfacePlugin.h"

/* Plugins/Emoticon Menu */
#import "BGEmoticonMenuPlugin.h"

/* Plugins/Error Message Handler */
#import "ErrorMessageHandlerPlugin.h"

/* Plugins/File Transfer Messages */
#import "ESFileTransferMessagesPlugin.h"

/* Plugins/General Preferences */
#import "ESGeneralPreferencesPlugin.h"

/* Plugins/Global Events Preferences */
#import "ESGlobalEventsPreferencesPlugin.h"

/* Plugins/Invite to Chat Plugin */
#import "DCInviteToChatPlugin.h"

/* Plugins/Join Chat Panel */
#import "DCJoinChatPanelPlugin.h"

/* Plugins/Link Management */
#import "SHLinkManagementPlugin.h"

/* Plugins/Logger */
#import "AILoggerPlugin.h"

/* Plugins/Message Alias Support */
#import "AIMessageAliasPlugin.h"

/* Plugins/Message Context Display */
#import "DCMessageContextDisplayPlugin.h"

/* Plugins/Message Events */
#import "ESMessageEvents.h"

/* Plugins/Open Message Window Contact Alert */
#import "ESOpenMessageWindowContactAlertPlugin.h"

/* Plugins/Safari Link Toolbar Item */
#import "ESSafariLinkToolbarItemPlugin.h"

/* Plugins/Secure Messaging */
#import "ESSecureMessagingPlugin.h"

/* Plugins/Send Message Contact Alert */
#import "ESSendMessageContactAlertPlugin.h"

/* Plugins/Spell Checking */
#import "AISpellCheckingPlugin.h"

/* Plugins/Status Menu Item */
#import "CBStatusMenuItemPlugin.h"

/* Plugins/URL Handling */
#import "CBURLHandlingPlugin.h"

/* Plugins/Video Chat Interface */
#import "AIVideoChatInterfacePlugin.h"

@interface AICoreComponentLoader (PRIVATE)
- (void)_loadComponentClass:(Class)inClass;
@end

@implementation AICoreComponentLoader

- (id)init
{
	if((self = [super init])){
		components = [[NSMutableArray alloc] init];
	}

	return self;
}

/*!
 * @brief Load integrated components
 */
- (void)initController
{
	[self _loadComponentClass:[AIAccountListPreferencesPlugin class]];
	[self _loadComponentClass:[AIAccountMenuAccessPlugin class]];
	[self _loadComponentClass:[AIAliasSupportPlugin class]];
	[self _loadComponentClass:[AIAppearancePreferencesPlugin class]];
	[self _loadComponentClass:[AIAutoIdlePlugin class]];
	[self _loadComponentClass:[AIAutoLinkingPlugin class]];
	[self _loadComponentClass:[AIAutoReplyPlugin class]];
	[self _loadComponentClass:[AIChatConsolidationPlugin class]];
	[self _loadComponentClass:[AIChatCyclingPlugin class]];
	[self _loadComponentClass:[AIContactAwayPlugin class]];
	[self _loadComponentClass:[AIContactIdlePlugin class]];
	[self _loadComponentClass:[AIContactListEditorPlugin class]];
	[self _loadComponentClass:[AIContactOnlineSincePlugin class]];
	[self _loadComponentClass:[AIContactSortSelectionPlugin class]];
	[self _loadComponentClass:[AIContactStatusColoringPlugin class]];
	[self _loadComponentClass:[AIContactStatusDockOverlaysPlugin class]];
	[self _loadComponentClass:[AIContactStatusEventsPlugin class]];
	[self _loadComponentClass:[AIContactWarningLevelPlugin class]];
	[self _loadComponentClass:[AIDefaultFormattingPlugin class]];
	[self _loadComponentClass:[AIDockAccountStatusPlugin class]];
	[self _loadComponentClass:[AIDockBehaviorPlugin class]];
	[self _loadComponentClass:[AIDockUnviewedContentPlugin class]];
	[self _loadComponentClass:[AIDualWindowInterfacePlugin class]];
	[self _loadComponentClass:[AIEventSoundsPlugin class]];
	[self _loadComponentClass:[AIExtendedStatusPlugin class]];
	[self _loadComponentClass:[AILoggerPlugin class]];
	[self _loadComponentClass:[AIMessageAliasPlugin class]];
	[self _loadComponentClass:[AINewMessagePanelPlugin class]];
	[self _loadComponentClass:[AIOfflineContactHidingPlugin class]];
	[self _loadComponentClass:[AISCLViewPlugin class]];
	[self _loadComponentClass:[AISpellCheckingPlugin class]];
	[self _loadComponentClass:[AIStandardToolbarItemsPlugin class]];
	[self _loadComponentClass:[AIStateMenuPlugin class]];
	[self _loadComponentClass:[AIStatusChangedMessagesPlugin class]];
	[self _loadComponentClass:[AITabStatusIconsPlugin class]];
	[self _loadComponentClass:[AITypingNotificationPlugin class]];
	[self _loadComponentClass:[AIVideoChatInterfacePlugin class]];
	[self _loadComponentClass:[BGContactNotesPlugin class]];
	[self _loadComponentClass:[BGEmoticonMenuPlugin class]];
	[self _loadComponentClass:[CBActionSupportPlugin class]];
	[self _loadComponentClass:[CBContactCountingDisplayPlugin class]];
	[self _loadComponentClass:[CBContactLastSeenPlugin class]];
	[self _loadComponentClass:[CBStatusMenuItemPlugin class]];
	[self _loadComponentClass:[CBURLHandlingPlugin class]];
	[self _loadComponentClass:[CPFVersionChecker class]];
	[self _loadComponentClass:[DCInviteToChatPlugin class]];
	[self _loadComponentClass:[DCJoinChatPanelPlugin class]];
	[self _loadComponentClass:[DCMessageContextDisplayPlugin class]];
	[self _loadComponentClass:[ESAccountEvents class]];
	[self _loadComponentClass:[ESAccountNetworkConnectivityPlugin class]];
	[self _loadComponentClass:[ESAddressBookIntegrationPlugin class]];
	[self _loadComponentClass:[ESAnnouncerPlugin class]];
	[self _loadComponentClass:[ESApplescriptContactAlertPlugin class]];
	[self _loadComponentClass:[ESBlockingPlugin class]];
	[self _loadComponentClass:[ESContactClientPlugin class]];
	[self _loadComponentClass:[ESContactServersideDisplayName class]];
	[self _loadComponentClass:[ESFastUserSwitchingSupportPlugin class]];
	[self _loadComponentClass:[ESFileTransferMessagesPlugin class]];
	[self _loadComponentClass:[ESMessageEvents class]];
	[self _loadComponentClass:[ESMetaContactContentsPlugin class]];
	[self _loadComponentClass:[ESOpenMessageWindowContactAlertPlugin class]];
	[self _loadComponentClass:[ESSafariLinkToolbarItemPlugin class]];
	[self _loadComponentClass:[ESSendMessageContactAlertPlugin class]];
	[self _loadComponentClass:[ESUserIconHandlingPlugin class]];
	[self _loadComponentClass:[ErrorMessageHandlerPlugin class]];
	[self _loadComponentClass:[GBApplescriptFiltersPlugin class]];
	[self _loadComponentClass:[SAContactOnlineForPlugin class]];
	[self _loadComponentClass:[SHLinkManagementPlugin class]];
	[self _loadComponentClass:[ESGlobalEventsPreferencesPlugin class]];
	[self _loadComponentClass:[ESGeneralPreferencesPlugin class]];
	[self _loadComponentClass:[NEHGrowlPlugin class]];
	[self _loadComponentClass:[ESSecureMessagingPlugin class]];
	[self _loadComponentClass:[ESStatusPreferencesPlugin class]];
	[self _loadComponentClass:[ESAutoAwayPlugin class]];
	[self _loadComponentClass:[ESAwayStatusWindowPlugin class]];
}

/*!
 * @brief Give all components a chance to close
 */
- (void)closeController
{
	NSEnumerator	*enumerator = [components objectEnumerator];
	AIPlugin		*plugin;

	while (plugin = [enumerator nextObject]) {
		[plugin uninstallPlugin];
	}
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[components release];
	components = nil;

	[super dealloc];
}

/*!
 * @brief Load an integrated component plugin
 *
 * @param inClass The class of the component, which must inherit from <tt>AIPlugin</tt>
 */
- (void)_loadComponentClass:(Class)inClass
{
	id object = [[inClass alloc] init];

	NSAssert1(object, @"Failed to load %@", NSStringFromClass(inClass));

	[components addObject:object];
	[object release];
}

@end
