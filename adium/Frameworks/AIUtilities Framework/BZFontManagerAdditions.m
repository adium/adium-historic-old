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

#import "BZFontManagerAdditions.h"

@implementation NSFontManager (BZFontManagerAdditions)

- (NSFont *)fontWithFamilyInsensitively:(NSString *)name traits:(NSFontTraitMask)fontTraitMask weight:(int)weight size:(float)size
{
	NSFont *theFont = nil;

	NSFontManager *manager = [NSFontManager sharedFontManager];
	NSArray *fontList = [manager availableFontFamilies];
	NSEnumerator *fontEnum = [fontList objectEnumerator];

	NSString *thisName = [fontEnum nextObject];
	for(; thisName; thisName = [fontEnum nextObject]) {
		if([thisName caseInsensitiveCompare:name] == NSOrderedSame) {
			theFont = [manager fontWithFamily:thisName traits:fontTraitMask weight:weight size:size];
			break;
		}
	}

	return theFont;
}

@end
