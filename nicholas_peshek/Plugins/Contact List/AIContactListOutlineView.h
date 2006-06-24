//
//  AIContactListOutlineView.h
//  Adium
//
//  Created by Nick Peshek on 6/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIListOutlineView.h>

@interface AIContactListOutlineView : AIListOutlineView {
	BOOL			isDroppedOutOfView;
	NSPasteboard	*tempDragBoard;
}

@end
