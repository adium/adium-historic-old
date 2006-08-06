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


#import <Adium/AIPlugin.h>
#import "SMSQLiteLogViewerWindowController.h"

#define PATH_LOGS                       @"/logs.db"

#define PREF_GROUP_LOGGING              @"Logging"
#define KEY_LOGGER_ENABLE               @"Enable Logging"
#define LOGGER_DID_UPDATE_ACCOUNT_LIST	@"LoggerDidUpdateAccountList"
#define LOGGER_DID_UPDATE_OTHERS_LIST	@"LoggerDidUpdateOthersList"
#define LOGGER_DID_ADD_MESSAGES			@"LoggerDidAddMessages"

#import "sqlite3.h"

@class SMSQLiteDatabase, SMLoggerContact, SMLoggerConversation, AIChat, AIQueue;

@interface SMSQLiteLoggerPlugin : AIPlugin {
	bool								observingContent;
	SMSQLiteDatabase					*database;
	SMSQLiteLogViewerWindowController	*logViewerWindow;
	
	NSMutableArray						*accounts, *others; // Local copy (er, not in the database)
	BOOL								accountsCurrent, othersCurrent; // Whether the above arrays need to be updated the next time they are requested
	
	BOOL								conversationListCurrent;
	BOOL								filteringForNothing, filteringForAccount;
	SMLoggerContact						*filterItem;
	NSMutableArray						*conversationList;
	
	AIQueue								*pendingMessages;
	NSAutoreleasePool					*autoreleasePool;
}

- (NSArray *)accounts;
- (NSArray *)others;
- (NSArray *)conversationList;

- (NSAttributedString *)conversationContents:(SMLoggerConversation *)conversation;

- (void)filterForContact:(SMLoggerContact *)contact;
- (void)filterForAccount:(SMLoggerContact *)account;
- (void)filterForNothing;

- (NSArray *)context:(int)count inChat:(AIChat *)chat;
@end
