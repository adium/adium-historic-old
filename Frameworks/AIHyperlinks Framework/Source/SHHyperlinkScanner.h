/*
 * The AIHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AIHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
