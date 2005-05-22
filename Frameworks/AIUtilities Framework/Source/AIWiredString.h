/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
//
//  AIWiredString.h
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-16.
//

#import <Cocoa/Cocoa.h>

@class AIWiredData;

@interface AIWiredString : NSString
{
	unichar *backing;
	size_t length;
}

- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding allowLossyConversion:(BOOL)flag;
- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding;

@end
