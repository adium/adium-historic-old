//
//  AITableViewAdditions.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTableView (AITableViewAdditions)

- (int)indexOfTableColumn:(NSTableColumn *)inColumn;
- (int)indexOfTableColumnWithIdentifier:(id)inIdentifier;

@end
