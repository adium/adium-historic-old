//
//  SHHyperlinkScanner.h
//  Adium
//
//  Created by Stephen Holt on Sun May 09 2004.

#import <Foundation/Foundation.h>

extern char* SHtext;
extern int SHleng;
extern int SHlex();
typedef struct SH_buffer_state *SH_BUFFER_STATE;
void SH_switch_to_buffer(SH_BUFFER_STATE);
SH_BUFFER_STATE SH_scan_string (const char *);
void SH_delete_buffer(SH_BUFFER_STATE);

extern unsigned int SHStringOffset;


@interface SHHyperlinkScanner : NSObject {

    BOOL     useStrictChecking;

}

-(id)init;
-(id)initWithStrictChecking:(BOOL)flag;

-(void)setStrictChecking:(BOOL)flag;
-(BOOL)isStrictCheckingEnabled;

-(BOOL)isStringValidURL:(NSString *)inString;
-(NSRange)nextURLFromString:(NSString *)inString;

-(NSArray *)allURLsFromString:(NSString *)inString;
-(NSArray *)allURLsFromTextView:(NSTextView *)inView;
-(NSAttributedString *)linkifyString:(NSAttributedString *)inString;
-(void)linkifyTextView:(NSTextView *)inView;

@end
