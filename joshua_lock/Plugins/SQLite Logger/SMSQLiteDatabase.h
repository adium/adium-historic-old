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

#import <Foundation/Foundation.h>
#import "sqlite3.h"

/*
 * Here we have a thread-safe SQLite database. Hurrah!
 */

@interface SMSQLiteDatabase : NSObject {
	sqlite3	*database;
	NSLock	*dbLock;
}
- (SMSQLiteDatabase *)initWithFileName:(NSString *)inFileName;
- (BOOL)query:(NSString *)queryString;

/*
 * Returns data into the string array pointed to by returnPointer in the format of:
 *   {"ColumnHeaderOne", "ColumnHeaderTwo", "ValueOne", "ValueTwo", "AValue", "AnotherValue"}.
 * Make sure you free the returned table by passing the string array pointed to by returnPointer to -freeData: after you are done with it;
 * we don't like leaks.
 */
- (BOOL)query:(NSString *)queryString rows:(int *)rowsPtr cols:(int *)colsPtr data:(char ***)returnPointer;

- (void)freeData:(char **)data;
- (int)lastInsertRowID;
@end
