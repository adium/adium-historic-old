//
//  AIContactListCollectionCell.h
//  Adium
//
//  Created by Adam Iser on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIContactListCollectionCell : NSCell <NSCopying> {
    NSString 		*label;
    NSString 		*subLabel;
}

- (void)setLabel:(NSString *)inLabel subLabel:(NSString *)inSubLabel;

@end
