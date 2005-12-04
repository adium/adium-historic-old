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

#import "SMSQLiteLoggerPlugin.h"
#import "SMSQLiteDatabase.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIQueue.h>
#import <Adium/AIAccount.h>
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import "AIInterfaceController.h"
#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "AIContentMessage.h"
#import <Adium/AIContentStatus.h>
#import "AIChat.h"
#import "AIListContact.h"
#import "AIService.h"
#import "AIContentContext.h"
#import "AIAccount.h"
#import "AILoginController.h"
#import "AIMenuController.h"
#import "SMLoggerContact.h"
#import "SMLoggerConversation.h"

#define LOG_VIEWER AILocalizedString(@"SQLite Log Viewer",nil)

@interface SMSQLiteLoggerPlugin (PRIVATE)
- (void)_addMessage:(NSAttributedString *)message dest:(NSString *)destName source:(NSString *)sourceName sendDisplay:(NSString *)sendDisp destDisplay:(NSString *)destDisp sendServe:(NSString *)s_service recServe:(NSString *)r_service isOutgoing:(BOOL)isOutgoing date:(NSDate *)messageDate isAutoreply:(BOOL)isAutoreply isStatus:(BOOL)isStatus;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSMutableSet *)wordsInString:(NSString *)string;
- (void)adiumSentOrReceivedContentObject:(AIContentMessage *)content;
@end

@implementation SMSQLiteLoggerPlugin

- (void)installPlugin
{
	accountsCurrent = NO;
	othersCurrent = NO;
	
	conversationList = nil;
	conversationListCurrent = NO;
	filteringForNothing = YES;
	filteringForAccount = NO;
	
	pendingMessages = [[AIQueue alloc] init];
	
	short	tablesCreated = 0;
	
	BOOL	dbError = NO;
	char	**tables;
	int		rows, cols;
	
	// Watch for pref changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LOGGING];

	// Create a log viewer window
	logViewerWindow = [[SMSQLiteLogViewerWindowController alloc] initWithPlugin:self];
		
	//Initialize database
	NSString *dbPath = [[[[adium loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
	database = [[SMSQLiteDatabase alloc] initWithFileName:dbPath];
	if (!database) { [self uninstallPlugin]; return; }

	dbError = [database query:@"SELECT name from sqlite_master where type='table'" rows:&rows cols:&cols data:&tables];
	if (!dbError) {
		int i;
		for (i=1; i<=rows; i++) {
			if (!strcmp("messages", tables[i]) || !strcmp("accounts", tables[i]) || !strcmp("others", tables[i]) || !strcmp("words", tables[i]) || !strcmp("messageIndex", tables[i])) {
				tablesCreated++;
				if (tablesCreated == 5)
					break;
			}
		}
		[database freeData:tables];
		if (tablesCreated < 5) {
			dbError = [database query:@"BEGIN TRANSACTION;"
							
							@"CREATE table messages (" // Contains actual messages
							@"id		        integer primary key," // Just a number for reference
							@"date              timestamp," // Timestamp (YYYY-MM-DD HH:MM:SS, but stored as a julian day)
							@"message           varchar(8096)," // The actual message
							@"account_id        integer," // References the accounts table
							@"other_id          integer," // References the others table
							@"sender_display    varchar(256)," // Display name (what is shown in place of the id)
							@"outgoing          boolean,"
							@"autoreply			boolean,"
							@"status			boolean"
							@");"
							
							@"CREATE table accounts (" // Contains all senders on this machine
							@"id                integer primary key," // Just a number for reference
							@"name              varchar(256)," // Screen name, etc.
							@"service           varchar(256)" // AIM, MSN, Jabber, etc.
							@");"
							@"CREATE index accounts_index ON accounts ('name', 'service');"
							
							@"CREATE table others (" // Contains all recipients of accounts
							@"id		        integer primary key," // Just a number for reference
							@"name              varchar(256)," // Screen name, etc.
							@"service           varchar(256)" // AIM, MSN, Jabber, etc.
							@");"
							@"CREATE index others_index ON others ('name', 'service');"
							
							@"CREATE table words (" // Contains words and integer identifiers used for indexing
							@"id                integer primary key," // identifier
							@"word              varchar(32)" // the word ("apple", "orange", "banana") in lowercase
							@");"
							@"CREATE index word_index ON words ( word );"
							
							@"CREATE table messageIndex (" // Contains means to find all messages that contain a word
							@"word              integer," // the index of the word in the "words" table
							@"message           integer"
							@");"
							@"CREATE index word_id_index ON messageIndex ( word );"
							
							@"COMMIT;"];
			if (dbError) { [self uninstallPlugin]; return; }
		}
	}
	
	[NSThread detachNewThreadSelector:@selector(messageAddingThread) toTarget:self withObject:nil];
	
	NSMenuItem *logViewerMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:LOG_VIEWER
																						  target:self
																						  action:@selector(showLogViewer:)
																				   keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxiliary];
}

- (void)uninstallPlugin
{
	[database release];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[logViewerWindow release];
	[others release];
	[accounts release];
	[conversationList release];
	[pendingMessages release]; pendingMessages = nil;
}


//Update for the new preferences
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	BOOL            newLogValue;
	
	//Start/Stop logging
	newLogValue = [[prefDict objectForKey:KEY_LOGGER_ENABLE] boolValue];
	if (newLogValue != observingContent) {
		observingContent = newLogValue;
		
		if (!observingContent) { //Stop Logging
			[[adium notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];
			
		} else { //Start Logging
			[[adium notificationCenter] addObserver:self selector:@selector(adiumSentOrReceivedContent:) name:Content_ContentObjectAdded object:nil];
		}
	}
}

- (void)addMessages:(NSTimer *)timer {
	AIContentMessage *content;
	while ((content = [pendingMessages dequeue])) {
		[self adiumSentOrReceivedContentObject:content];
	}
	[autoreleasePool release];
	autoreleasePool = [[NSAutoreleasePool alloc] init];
	
}

//Content was sent or recieved (add to queue)
- (void)adiumSentOrReceivedContent:(NSNotification *)notification
{
	AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
	[pendingMessages enqueue:content];
}

//Content was sent or recieved (do work now)
- (void)adiumSentOrReceivedContentObject:(AIContentMessage *)content;
{
    //Message Content
    if ([content postProcessContent]) {
        AIChat		*chat = [content chat];
        AIListObject	*source = [content source];
        AIListObject	*destination = [content destination];
        AIAccount	*account = [chat account];
		
        NSString	*srcDisplay = nil;
        NSString	*destDisplay = nil;
        NSString	*destUID = nil;
        NSString	*srcUID = nil;
        NSString	*destSrv = nil;
        NSString	*srcSrv = nil;
		
        if ([[account UID] isEqual:[source UID]]) {
#warning I think it would be better to use the destination of the message as a test here, but I am not sure.
            destUID  = [chat name];
            if (!destUID) {
                destUID = [[chat listObject] UID];
                destDisplay = [[chat listObject] displayName];
            }
            else {
                destDisplay = [chat displayName];;
            }
            destSrv = [[[chat account] service] serviceID];
            srcDisplay = [source displayName];
            srcUID = [source UID];
            srcSrv = [[source service] serviceID];
        } else {
            destUID = [chat name];
            if (!destUID) {
                srcDisplay = [[chat listObject] displayName];
                srcUID = [[chat listObject] UID];
                destUID = [destination UID];
                destDisplay = [destination displayName];
            }
            else {
                srcUID = [source UID];
                srcDisplay = srcUID;
                destDisplay = [chat displayName];
            }
            srcSrv = [[[chat account] service] serviceID];
            destSrv = srcSrv;
        }
		
        if (account && source) {
            //Log the message
			if ([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
					[self _addMessage:[[content message] attributedStringByConvertingAttachmentsToStrings]
								 dest:destUID
							   source:srcUID
						  sendDisplay:srcDisplay
						  destDisplay:destDisplay
							sendServe:srcSrv
							 recServe:destSrv
						   isOutgoing:[content isOutgoing]
								 date:[content date]
						  isAutoreply:[content isAutoreply]
							 isStatus:NO];
			} 
			else if ([[content type] isEqualToString:CONTENT_STATUS_TYPE]) {
				[self _addMessage:[[content message] attributedStringByConvertingAttachmentsToStrings]
							 dest:destUID
						   source:srcUID
					  sendDisplay:srcDisplay
					  destDisplay:destDisplay
						sendServe:srcSrv
						 recServe:destSrv
					   isOutgoing:[content isOutgoing]
							 date:[content date]
					  isAutoreply:NO
						 isStatus:YES];
			}
        }
    }
}

//Insert a message
- (void)_addMessage:(NSAttributedString *)message
               dest:(NSString *)destName
             source:(NSString *)sourceName
        sendDisplay:(NSString *)sendDisp
        destDisplay:(NSString *)destDisp
          sendServe:(NSString *)s_service
           recServe:(NSString *)r_service
		 isOutgoing:(BOOL)isOutgoing
			   date:(NSDate *)messageDate
		isAutoreply:(BOOL)isAutoreply
		   isStatus:(BOOL)isStatus;

{
	BOOL		dbError = NO;
	char		**results;
	int			rows, cols;

	int			messageID;
	int			accountID, otherID;
	NSString	*otherService, *accountService;
	NSString	*otherIDString, *accountIDString;
	
    NSMutableString 	*escapeHTMLMessage;
	NSMutableSet		*words;
	NSString			*currentWord;
	
	words = [self wordsInString:[message string]];
	int wordIDs[[words count] - 1];
	short currentWordID = 0;
	
    escapeHTMLMessage = [NSMutableString stringWithString:[AIHTMLDecoder encodeHTML:message
																			headers:NO
																		   fontTags:NO
																 includingColorTags:NO
																	  closeFontTags:NO
																		  styleTags:YES
														 closeStyleTagsOnFontChange:YES
																	 encodeNonASCII:YES
																	   encodeSpaces:YES
																		 imagesPath:nil
																  attachmentsAsText:YES
													 attachmentImagesOnlyForSending:NO
																	 simpleTagsOnly:NO
																	 bodyBackground:NO]];
	NSString *time = [messageDate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
	otherService = isOutgoing ? r_service : s_service;
	accountService = isOutgoing ? s_service : r_service;
	otherIDString = isOutgoing ? destName : sourceName;
	accountIDString = isOutgoing ? sourceName :   destName;
	
	[database query:@"BEGIN TRANSACTION"];
	
	dbError = [database query:[NSString stringWithFormat:@"SELECT id FROM accounts WHERE (name='%@' and service='%@') limit 1", accountIDString, accountService] rows:&rows cols:&cols data:&results];
	if (dbError) {[database query:@"ROLLBACK;"]; return;}	
	
	if (rows > 0)
		accountID = (int)strtol(results[1], NULL, 10);
	else {
		dbError = [database query:[NSString stringWithFormat:@"INSERT INTO accounts (name, service) VALUES ('%@', '%@')", accountIDString, accountService]];
		if (dbError) {[database query:@"ROLLBACK;"]; return;}
		[[adium notificationCenter] postNotificationName:LOGGER_DID_UPDATE_ACCOUNT_LIST object:nil];
		accountsCurrent = NO;
		accountID = [database lastInsertRowID];
	}
	[database freeData:results];
	
	dbError = [database query:[NSString stringWithFormat:@"SELECT id FROM others where (name='%@' and service='%@') limit 1", otherIDString, otherService] rows:&rows cols:&cols data:&results];
	if (dbError) return;
	
	if (rows > 0)
		otherID = (int)strtol(results[1], NULL, 10);
	else {
		dbError = [database query:[NSString stringWithFormat:@"INSERT INTO others (name, service) VALUES ('%@', '%@')", otherIDString, otherService] rows:&rows cols:&cols data:&results];
		if (dbError) {[database query:@"ROLLBACK;"]; return;}
		[[adium notificationCenter] postNotificationName:LOGGER_DID_UPDATE_OTHERS_LIST object:nil];
		othersCurrent = NO;
		otherID = [database lastInsertRowID];
	}
	[database freeData:results];
	
    // Escape the query inputs by doubling single quote characters
	char *sqlStatement = sqlite3_mprintf("INSERT INTO messages "
								   "(date, message, account_id, other_id, sender_display, outgoing, autoreply, status)" 
								   "VALUES (julianday('%q'), '%q', %d, %d, '%q', %d, %d, %d)",
								   [time UTF8String], [escapeHTMLMessage UTF8String], accountID, otherID, [sendDisp UTF8String], isOutgoing, isAutoreply, isStatus);
	dbError = [database query:[NSString stringWithUTF8String:sqlStatement]];
	sqlite3_free(sqlStatement);
	
	if (dbError) {[database query:@"ROLLBACK;"]; return;}
	
	messageID = [database lastInsertRowID];
	if ([words count] > 0) {
		dbError = [database query:[NSString stringWithFormat:@"SELECT id, word from words WHERE (word='%@');", [[words allObjects] componentsJoinedByString:@"' OR word='"]] rows:&rows cols:&cols data:&results];
		if (dbError) {[database query:@"ROLLBACK;"]; return;}
		int i;
		for (i=0; i<rows; i++) {
			if ((currentWord = [words member:[NSString stringWithUTF8String:results[3 + 2*i]]])) { // Skip headers (indices 0 and 1) and go for the word (after id)
				[words removeObject:currentWord];
				wordIDs[currentWordID] = atoi(results[2 + 2*i]);
				currentWordID++;
			}
		}
		[database freeData:results];
		
		NSEnumerator *enumerator = [words objectEnumerator];
		
		while ((currentWord = [enumerator nextObject])) {
			dbError = [database query:[NSString stringWithFormat:@"INSERT INTO words ('word') VALUES ('%@');", currentWord]];
			if (dbError) {[database query:@"ROLLBACK;"]; return;}
			
			wordIDs[currentWordID] = [database lastInsertRowID];
			currentWordID++;
		}
		for (currentWordID--; currentWordID >= 0; currentWordID--) {
			dbError = [database query:[NSString stringWithFormat:@"INSERT INTO messageIndex ('word', 'message') VALUES (%d, %d)", wordIDs[currentWordID], messageID]];
			if (dbError) {[database query:@"ROLLBACK;"]; return;}
			
		}
	}
	[database query:@"COMMIT;"];
}

- (void)messageAddingThread {
	NSTimer *messageAddingTimer;
	
	autoreleasePool = [[NSAutoreleasePool alloc] init];
	messageAddingTimer = [[NSTimer scheduledTimerWithTimeInterval:5 // once every five seconds
												  target:self
												selector:@selector(addMessages:)
												userInfo:nil
												 repeats:YES] retain];
	
	CFRunLoopRun();
	
	[messageAddingTimer invalidate]; [messageAddingTimer release];
	[autoreleasePool release];
}

- (NSArray *)accounts {
	if (!accountsCurrent) {
		char		**results;
		int			rows, cols;
		int			i;
		BOOL		dbError;
		SMLoggerContact *currentContact;
		
		if (others)
			[others release];
		
		dbError = [database query:@"SELECT id,name,service FROM accounts GROUP BY service,name;" rows:&rows cols:&cols data:&results];
		if (dbError) return 0;
		accounts = [[NSMutableArray arrayWithCapacity:rows] retain];
		for (i=1;i<=rows;i++) {
			currentContact = [[SMLoggerContact alloc] initWithIdentifier:[NSString stringWithUTF8String:results[3*i + 1]] service:[NSString stringWithUTF8String:results[3*i + 2]] dbIdentifier:(int)strtol(results[3*i], NULL, 10) isAccount:YES];
			[accounts addObject:currentContact];
			[currentContact release];
		}
		[database freeData:results];
		accountsCurrent = YES;
	}
	return accounts;
}

- (NSArray *)others {
	if (!othersCurrent) {
		char		**results;
		int			rows, cols;
		int			i;
		BOOL		dbError;
		SMLoggerContact *currentContact;
		
		if (others)
			[others release];
		
		dbError = [database query:@"SELECT id,name,service FROM others GROUP BY service,name;" rows:&rows cols:&cols data:&results];
		if (dbError) return 0;
		others = [[NSMutableArray arrayWithCapacity:rows] retain];
		for (i=1;i<=rows;i++) {
			currentContact = [[SMLoggerContact alloc] initWithIdentifier:[NSString stringWithUTF8String:results[3*i + 1]] service:[NSString stringWithUTF8String:results[3*i + 2]] dbIdentifier:(int)strtol(results[3*i], NULL, 10) isAccount:NO];
			[others addObject:currentContact];
			[currentContact release];
		}
		[database freeData:results];
		othersCurrent = YES;
	}
	return others;
}

- (void)filterForContact:(SMLoggerContact *)contact {
	filteringForNothing = NO;
	filteringForAccount = NO;
	if (!conversationListCurrent)
		[filterItem release];
	filterItem = [contact retain];
	conversationListCurrent = NO;
}

- (void)filterForAccount:(SMLoggerContact *)account {
	filteringForNothing = NO;
	filteringForAccount = YES;
	if (!conversationListCurrent)
		[filterItem release];
	filterItem = [account retain];
	conversationListCurrent = NO;
}

- (void)filterForNothing {
	filteringForNothing = YES;
	filteringForAccount = NO;
	if (!conversationListCurrent)
		[filterItem release];
	filterItem = nil;
	conversationListCurrent = NO;
}

/* 
Search for words
select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, a.name as account_name, o.name as other_name, a.service as message_service from messages m, accounts a, others o where m.other_id = o.id AND m.account_id = a.id AND m.id in (select message from messageIndex where word in (select id from words where (word = '%@')));

Filter by account
select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, '%@' as account_name, o.name as other_name, '%@' as message_service from messages m, accounts a, others o where m.account_id = a.id and a.name = account_name and a.service = message_service and o.id = m.other_id;

Filter by contact
select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, a.name as account_name, '%@' as other_name, '%@' as message_service from messages m, accounts a, others o where m.account_id = a.id and a.name = account_name and a.service = message_service and o.id = m.other_id;

Filter for nothing
select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, a.name as account_name, o.name as other_name, a.service as message_service from messages m, accounts a, others o where m.account_id = a.id and a.name = account_name and a.service = message_service and o.id = m.other_id;
*/

- (NSArray *)conversationList {
	if (!conversationListCurrent) {
		char		**results;
		int			rows, cols;
		int			i;
		BOOL		dbError;
		SMLoggerConversation *currentConversation;
		
		if (conversationList)
			[conversationList release];
		
		/* okay, I'm not quite sure these queries are optimal, feel free to make them better */
		
		if (filteringForNothing) { // Return all conversations
			dbError = [database query:@"select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, a.name as account_name, o.name as other_name, a.service as message_service from messages m, accounts a, others o where a.id = m.account_id and o.id = m.other_id;" rows:&rows cols:&cols data:&results];
		}
		else if (filteringForAccount) { // Return all conversations for account filterItem
			dbError = [database query:[NSString stringWithFormat:@"select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, '%@' as account_name, o.name as other_name, '%@' as message_service from messages m, accounts a, others o where m.account_id = a.id and a.name = account_name and a.service = message_service and o.id = m.other_id;", [filterItem identifier], [filterItem service]] rows:&rows cols:&cols data:&results];
		}
		else { // Return all conversations for contact filterItem
			dbError = [database query:[NSString stringWithFormat:@"select distinct date(m.date) as day, m.account_id as account_id, m.other_id as other_id, a.name as account_name, '%@' as other_name, '%@' as message_service from messages m, accounts a, others o where m.account_id = a.id and a.name = account_name and a.service = message_service and o.id = m.other_id and o.name = other_name;", [filterItem identifier], [filterItem service]] rows:&rows cols:&cols data:&results];
		}
		
		if (dbError) return [NSArray array];
		conversationList = [[NSMutableArray arrayWithCapacity:rows] retain];
		for (i=1;i<=rows;i++) {
			currentConversation = [[SMLoggerConversation alloc] initWithDay:[NSCalendarDate dateWithString:[NSString stringWithUTF8String:results[6*i]] calendarFormat:@"%Y-%m-%d"] 
																	account:[[[SMLoggerContact alloc] initWithIdentifier:[NSString stringWithUTF8String:results[6*i + 3]] service:[NSString stringWithUTF8String:results[6*i + 5]] dbIdentifier:(int)strtol(results[6*i + 1], NULL, 10) isAccount:YES] autorelease]
																	  other:[[[SMLoggerContact alloc] initWithIdentifier:[NSString stringWithUTF8String:results[6*i + 4]] service:[NSString stringWithUTF8String:results[6*i + 5]] dbIdentifier:(int)strtol(results[6*i + 2], NULL, 10) isAccount:YES] autorelease]];
			[conversationList addObject:currentConversation];
			[currentConversation release];
		}
		[database freeData:results];
		conversationListCurrent = YES;
		[filterItem release];
	}
	return conversationList;
}

- (NSAttributedString *)conversationContents:(SMLoggerConversation *)conversation {
	NSAttributedString *logText;
	NSMutableString *logHTMLText = [[[NSMutableString alloc] init] autorelease];
	
	char		**results;
	int			rows, cols;
	int			i;
	BOOL		dbError;
	
	dbError = [database query:[NSString stringWithFormat:@"select ('<div class=\"' || CASE status WHEN 0 THEN (CASE outgoing WHEN 0 THEN 'send' WHEN 1 THEN 'receive' END || '\"><span class=\"timestamp\">' || time(date) || '</span> <span class=\"sender\">' || sender_display || CASE autoreply WHEN 0 THEN '' WHEN 1 THEN ' (Autoreply)' END || ': </span><pre class=\"message\">' || message || '</pre>' ) WHEN 1 THEN ('status>' || message || ' (' || time(date) || ')') END || '</div>') from messages where date(date) = '%@' and other_id = %d;", [[conversation day] descriptionWithCalendarFormat:@"%Y-%m-%d"], [[conversation other] dbIdentifier]] rows:&rows cols:&cols data:&results];
	if (dbError) return [NSAttributedString stringWithString:@""];
	
	for (i = 1; i <= rows; i++) {
		[logHTMLText appendString:[NSString stringWithUTF8String:results[i]]];
		[logHTMLText appendString:@"\n"];
	}
	[database freeData:results];
	logText = [[[NSAttributedString alloc] initWithAttributedString:[AIHTMLDecoder decodeHTML:logHTMLText]] autorelease];
	logText = [logText stringByAddingFormattingForLinks];
	logText = [[adium contentController] filterAttributedString:logText
												usingFilterType:AIFilterMessageDisplay
													  direction:AIFilterOutgoing
														context:nil];
	
	return logText;
}

- (NSMutableSet *)wordsInString:(NSString *)string {
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	NSMutableSet *words = [[[NSMutableSet alloc] init] autorelease];
	NSCharacterSet *skippedCharacters = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
	NSString *word;
	
	[scanner setCharactersToBeSkipped:skippedCharacters];
	while ([scanner scanUpToCharactersFromSet:skippedCharacters intoString:&word]) {
		word = [word lowercaseString];
		if ([word length] > 32) {
			word = [word substringToIndex:31];
		}
		
		if (![words containsObject:word]) {
			[words addObject:word];
		}
	}
	
	[scanner release];
	return words;
}

- (void)showLogViewer:(id)sender {
	[logViewerWindow showWindow:nil];
}

- (NSArray *)context:(int)count inChat:(AIChat *)chat {
    AIAccount *account = [chat account];
    AIListObject *other = [chat listObject];
    
    char        **results;
    int         rows, cols;
    int         i;
    BOOL        dbError;
    
    BOOL outgoing;
    
    AIContentContext *currentContext;
    NSMutableArray *context;
    
    dbError = [database query:[NSString stringWithFormat:@"select datetime(date), message, outgoing, autoreply from messages where status = 0 AND other_id = (select id from others where name = '%@' and service = '%@') order by date desc limit %d;", [other UID], [[other service] serviceID], count] rows:&rows cols:&cols data:&results];
    if (dbError) return [NSArray array];
    context = [NSMutableArray arrayWithCapacity:rows];
    for (i = 1; i <= rows; i++) {
        outgoing = (results[4*i + 2][0] == '1');
        currentContext = [AIContentContext messageInChat:chat
                                              withSource:(outgoing ? account : other) 
                                             destination:(outgoing ? other : account)
                                                    date:[NSCalendarDate dateWithString:[NSString stringWithUTF8String:results[4*i]] calendarFormat:@"%Y-%m-%d %H:%M:%S"]
                                                 message:[[[NSAttributedString alloc] initWithAttributedString:[AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String:results[4*i + 1]]]] autorelease]
                                               autoreply:(results[4*i + 3][0] == '1')];
        [context addObject:currentContext];
    }
    [database freeData:results];
    
    return context;
}
@end
