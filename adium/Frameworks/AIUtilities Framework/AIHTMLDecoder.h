/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIStringAdditions.h"

@interface AIHTMLDecoder : NSObject {

}

+ (NSAttributedString *)decodeHTML:(NSString *)inMessage;
+ (NSString *)encodeHTML:(NSAttributedString *)inMessage encodeFullString:(BOOL)encodeFullString;
+ (NSString *)encodeHTML:(NSAttributedString *)inMessage headers:(BOOL)includeHeaders fontTags:(BOOL)includeFontTags includingColorTags:(BOOL)includeColorTags closeFontTags:(BOOL)closeFontTags styleTags:(BOOL)includeStyleTags closeStyleTagsOnFontChange:(BOOL)closeStyleTagsOnFontChange encodeNonASCII:(BOOL)encodeNonASCII imagesPath:(NSString *)imagesPath attachmentsAsText:(BOOL)attachmentsAsText simpleTagsOnly:(BOOL)simpleOnly;

@end
