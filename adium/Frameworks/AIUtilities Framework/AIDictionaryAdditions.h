/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface NSDictionary (AIDictionaryAdditions)

+ (NSDictionary *)dictionaryNamed:(NSString *)name forClass:(Class)inClass;
+ (NSDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create;
- (void)writeToPath:(NSString *)path withName:(NSString *)name;
- (BOOL)boolForKey:(NSString *)inKey;
- (NSString *)stringForKey:(NSString *)inKey;
- (int)intForKey:(NSString *)inKey;
- (NSColor *)colorForKey:(NSString *)inKey;
- (id)objectForIntegerKey:(int)aKey;

@end

@interface NSMutableDictionary (AIDictionaryAdditions)

+ (NSMutableDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create;
- (void)setBool:(BOOL)inValue forKey:(NSString *)inKey;
- (void)setString:(NSString *)inString forKey:(NSString *)inKey;
- (void)setInt:(int)inValue forKey:(NSString *)inKey;
- (void)setColor:(NSColor *)inColor forKey:(NSString *)inKey;
- (id)objectForIntegerKey:(int)aKey;

@end
