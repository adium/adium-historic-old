//
//  IKTableImageCell.h
//  Adium
//
//  Created by Ian Krieg on Mon Jul 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Currently researching whether I actually need to write this...
@interface IKTableImageCell : NSCell {
    //NSImage			*image;
    BOOL			highlighted;
    BOOL			objectEnabled;
}

- (void)setObjectEnabled:(BOOL)enabled;
- (BOOL)isObjectEnabled;
@end
