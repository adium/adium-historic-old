//
//  AISMViewController.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIUtilities/AIUtilities.h>

@class AIContactHandle, AIAdium, AIFlexibleTableView, AIFlexibleTableColumn;

@interface AISMViewController : NSObject <AIFlexibleTableViewDelegate> {
    AIAdium			*owner;

    AIContactHandle		*handle;
    AIFlexibleTableView		*messageView;

    AIFlexibleTableColumn	*senderCol;
    AIFlexibleTableColumn	*messageCol;
    AIFlexibleTableColumn	*timeCol;

    NSColor			*backColorIn;
    NSColor			*backColorOut;
    NSColor			*lineColorDivider;
    NSColor			*lineColorDarkDivider;
    NSColor			*outgoingSourceColor;
    NSColor			*incomingSourceColor;
}

+ (AISMViewController *)messageViewControllerForHandle:(AIContactHandle *)inHandle owner:(id)inOwner;
- (NSView *)messageView;

@end
