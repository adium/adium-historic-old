//
//  AICheckboxList.h
//  Adium
//
//  Created by Ian Krieg on Sat Jul 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface AICheckboxList : NSScrollView {
	NSMutableArray	*checkboxes;
	NSView			*content;
	
	float			nextOffset;
}

- (BOOL)addItemName:(NSString*)name state:(int)setState;	// Returns false if name is already in the list
- (int)itemState:(NSString*)name;
- (void)setItemState:(NSString*)name	state:(int)state;
- (void)removeItemName:(NSString*)name;

@end
