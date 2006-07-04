//
//  SmackXMPPFormConverter.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SmackXForm;

@interface SmackXMPPFormConverter : NSObject {
    SmackXForm *form;
}

- (id)initWithForm:(SmackXForm*)f;

- (NSData*)toXHTML;

@end
