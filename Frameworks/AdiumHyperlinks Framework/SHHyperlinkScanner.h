//
//  SHHyperlinkScanner.h
//  Adium
//
//  Created by Stephen Holt on Sun May 09 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "SHLinkLexer.h"

extern char* SHtext;
extern int SHleng;
extern int SHlex();
typedef struct SH_buffer_state *SH_BUFFER_STATE;
void SH_switch_to_buffer(SH_BUFFER_STATE);
SH_BUFFER_STATE SH_scan_string (const char *);
void SH_delete_buffer(SH_BUFFER_STATE);

extern unsigned int SHStringOffset;

@class SHMarkedHyperlink;
@interface SHHyperlinkScanner : NSObject {

    BOOL                        useStrictChecking;
    URI_VERIFICATION_STATUS     validStatus;

}

-(id)init;
-(id)initWithStrictChecking:(BOOL)flag;

-(void)setStrictChecking:(BOOL)flag;
-(BOOL)isStrictCheckingEnabled;
-(URI_VERIFICATION_STATUS)validationStatus;

-(BOOL)isStringValidURL:(NSString *)inString;
-(SHMarkedHyperlink *)nextURLFromString:(NSString *)inString;

-(NSArray *)allURLsFromString:(NSString *)inString;
-(NSArray *)allURLsFromTextView:(NSTextView *)inView;
-(NSAttributedString *)linkifyString:(NSAttributedString *)inString;
-(void)linkifyTextView:(NSTextView *)inView;

@end
