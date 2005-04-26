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

#import "SHLinkLexer.h"

extern int SHleng;
extern int SHlex();
typedef struct SH_buffer_state *SH_BUFFER_STATE;
void SH_switch_to_buffer(SH_BUFFER_STATE);
SH_BUFFER_STATE SH_scan_string (const char *);
void SH_delete_buffer(SH_BUFFER_STATE);

extern unsigned int SHStringOffset;

@class SHMarkedHyperlink;

@interface SHHyperlinkScanner : NSObject
{
	NSDictionary				*urlSchemes;
	BOOL						 useStrictChecking;
	URI_VERIFICATION_STATUS		 validStatus;
}

- (id)init;
- (id)initWithStrictChecking:(BOOL)flag;

- (URI_VERIFICATION_STATUS)validationStatus;

- (BOOL)isStringValidURL:(NSString *)inString;
- (SHMarkedHyperlink *)nextURLFromString:(NSString *)inString;

- (NSArray *)allURLsFromString:(NSString *)inString;
- (NSArray *)allURLsFromTextView:(NSTextView *)inView;
- (NSAttributedString *)linkifyString:(NSAttributedString *)inString;
- (void)linkifyTextView:(NSTextView *)inView;

@end
