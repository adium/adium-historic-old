//
//  SHAutoValidatingTextView.m
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.


#import "SHAutoValidatingTextView.h"

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
    //toggle the validation BOOL, and immeditely re-evaluate view
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
- (URI_VERIFICATION_STATUS)validationStatus
{
    return(validStatus);
}
#pragma mark Evaluate URL
//catch the notification when the text in the view is edited
- (void)textDidChange:(NSNotification *)notification
{
    if(continiousURLValidation) {//call the URL validatation if set
        SHHyperlinkScanner  *laxScanner = [[SHHyperlinkScanner alloc] initWithStrictChecking:NO];
        
        URLIsValid = [laxScanner isStringValidURL:[[self textStorage] string]];
        validStatus = [laxScanner validationStatus];
    }
}

@end
