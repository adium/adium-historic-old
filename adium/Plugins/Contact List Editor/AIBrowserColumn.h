//
//  AIBrowserColumn.h
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AIBrowserColumn : NSObject {
	NSScrollView	*scrollView;
	NSTableView		*tableView;
	id				representedObject;
}

- (id)initWithScrollView:(id)inScroll tableView:(id)inTable representedObject:(id)inObject;
- (void)dealloc;
- (NSScrollView *)scrollView;
- (NSTableView *)tableView;
- (id)representedObject;

@end
