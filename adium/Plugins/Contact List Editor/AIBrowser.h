//
//  AIBrowser.h
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


@interface AIBrowser : NSView {
	NSScrollView	*rootColumn;
	NSMutableArray	*columnArray;
	NSMutableArray	*representedObjects;
	id				dataSource;
}

- (void)setDataSource:(id)inDataSource;
- (id)dataSource;

@end
