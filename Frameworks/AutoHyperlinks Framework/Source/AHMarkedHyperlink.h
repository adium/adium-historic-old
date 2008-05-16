/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
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

#import "AHLinkLexer.h"


@interface AHMarkedHyperlink : NSObject {
    NSRange                      linkRange;
    NSURL                       *linkURL;
    NSString                    *pString;
    AH_URI_VERIFICATION_STATUS      urlStatus;
}

-(id)initWithString:(NSString *)inString withValidationStatus:(AH_URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange;
-(NSString *)parentString;
-(NSRange)range;
-(NSURL *)URL;
-(AH_URI_VERIFICATION_STATUS)validationStatus;
-(BOOL)parentStringMatchesString:(NSString *)inString;

-(void)setRange:(NSRange)inRange;
-(void)setURL:(NSURL *)inURL;
-(void)setURLFromString:(NSString *)inString;
-(void)setValidationStatus:(AH_URI_VERIFICATION_STATUS)status;
-(void)setParentString:(NSString *)pInString;


@end
