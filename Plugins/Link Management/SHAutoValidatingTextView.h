//
//  SHAutoValidatingTextView.h
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//
 
@interface SHAutoValidatingTextView : NSTextView {

    BOOL                         continiousURLValidation;
    BOOL                         URLIsValid;
    NSString                    *urlString;
    unsigned                     scanOffset;
    URI_VERIFICATION_STATUS      validStatus;
}

- (void)setContiniousURLValidationEnabled:(BOOL)flag;
- (void)toggleContiniousURLValidationEnabled;
- (BOOL)isContiniousURLValidationEnabled;
- (URI_VERIFICATION_STATUS)validationStatus;
- (BOOL)isURLValid;

@end
