//
//  SHAutoValidatingTextView.h
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.

//C prototypes for lexer
extern char* SHLinkLexertext;
extern int SHLinkLexerlex();
typedef struct SHLinkLexer_buffer_state *SHLinkLexer_BUFFER_STATE;
void SHLinkLexer_switch_to_buffer(SHLinkLexer_BUFFER_STATE);
SHLinkLexer_BUFFER_STATE SHLinkLexer_scan_string (const char *);
void SHLinkLexer_delete_buffer(SHLinkLexer_BUFFER_STATE);

 
@interface SHAutoValidatingTextView : NSTextView {

    BOOL         continiousURLValidation;
    BOOL         URLIsValid;
    NSString    *urlString;
    unsigned     scanOffset;

}

- (void)setContiniousURLValidationEnabled:(BOOL)flag;
- (void)toggleContiniousURLValidationEnabled;
- (BOOL)isContiniousURLValidationEnabled;

- (BOOL)isURLValid;

@end
