//
//  SHAutoValidatingTextView.h
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.

 
@interface SHAutoValidatingTextView : NSTextView {

    BOOL         continiousURLValidation;
    BOOL         URLIsValid;
    NSString    *urlString;
    unsigned     scanOffset;
    int          validStatus;
}

- (void)setContiniousURLValidationEnabled:(BOOL)flag;
- (void)toggleContiniousURLValidationEnabled;
- (BOOL)isContiniousURLValidationEnabled;
- (int)validationStatus;
- (BOOL)isURLValid;

@end
