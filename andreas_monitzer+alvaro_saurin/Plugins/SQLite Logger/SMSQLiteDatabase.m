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

#import "SMSQLiteDatabase.h"
#import "AIInterfaceController.h"

@interface SMSQLiteDatabase (PRIVATE)
- (BOOL)errorCheck:(NSString *)query;
@end

@implementation SMSQLiteDatabase
- (SMSQLiteDatabase *)initWithFileName:(NSString *)inFileName {
	if ((self = [super init])) {
		dbLock = [[NSLock alloc] init];
		sqlite3_open([inFileName UTF8String], &database);
		if ([self errorCheck:@"DB Open"]) {
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (void)dealloc {
	[dbLock lock];
	sqlite3_close(database);
	[dbLock unlock];
	[dbLock release];
	[super dealloc];
}

- (BOOL)query:(NSString *)queryString {
	[dbLock lock];
	sqlite3_exec(database, [queryString UTF8String], NULL, NULL, NULL);
	[dbLock unlock];
	return [self errorCheck:queryString];
}

- (BOOL)query:(NSString *)queryString rows:(int *)rowsPtr cols:(int *)colsPtr data:(char ***)returnPointer {
	[dbLock lock];
	sqlite3_get_table(database, [queryString UTF8String], returnPointer, rowsPtr, colsPtr, NULL);
	[dbLock unlock];
	return [self errorCheck:queryString];
}

- (void)freeData:(char **)data {
	sqlite3_free_table(data);
}

- (int)lastInsertRowID {
	[dbLock lock];
	int rowID = sqlite3_last_insert_rowid(database);
	[dbLock unlock];
	return rowID;
}

- (BOOL)errorCheck:(NSString *)query {
	[dbLock lock];
	if (sqlite3_errcode(database) != SQLITE_OK) {
		NSLog(@"SQLite Error %d: %s\nQuery was: %@", sqlite3_errcode(database), sqlite3_errmsg(database), query);
		[dbLock unlock];
		return YES;
	}
	[dbLock unlock];
	return NO;
}
@end
