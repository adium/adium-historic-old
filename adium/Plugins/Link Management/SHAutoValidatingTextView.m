//
//  SHAutoValidatingTextView.m
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.


#import "SHAutoValidatingTextView.h"
#import "SHLinkLexer.h"

@interface SHAutoValidatingTextView (PRIVATE)
- (BOOL)_validateURL;
@end

@implementation SHAutoValidatingTextView

- (id)initWithFrame:(NSRect)frameRect
{
    return([super initWithFrame:frameRect]);
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
    return([super initWithFrame:frameRect textContainer:aTextContainer]);
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Set Validation Attribs
- (void)setContiniousURLValidationEnabled:(BOOL)flag
{
    //set the validation BOOL, and immeditely reevaluate view
    continiousURLValidation = flag;
}

- (void)toggleContiniousURLValidationEnabled
{
    //toggle the validation BOOL, and immeditely reevaluate view
    continiousURLValidation = !continiousURLValidation;
}

- (BOOL)isContiniousURLValidationEnabled
{
    return(continiousURLValidation);
}
#pragma mark Get URL Verification Status
- (BOOL)isURLValid
{
    return(URLIsValid);
}
- (int)validationStatus
{
    return(validStatus);
}
#pragma mark Evaluate URL
//catch the notification when the text in the view is edited
- (void)textDidChange:(NSNotification *)notification
{
    if(continiousURLValidation) {//call the URL validatation if set
        URLIsValid = [self _validateURL];
    }
}

- (BOOL)_validateURL // Now with FLEX!
{
    validStatus = 0;
    SHLinkLexer_BUFFER_STATE buf;
    
    //init buffer to scan a string
    buf = SHLinkLexer_scan_string([[[self textStorage] string] UTF8String]);
    SHLinkLexer_switch_to_buffer(buf);
    
    //return the lexer's state
    validStatus = SHLinkLexerlex();
    if( validStatus != SH_URL_INVALID) {
        SHLinkLexer_delete_buffer(buf);
        return YES;
    }else{
        SHLinkLexer_delete_buffer(buf);
        return NO;
    }
}

@end
