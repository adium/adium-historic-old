//
//  AIStatusSelectionView.h
//  Adium
//
//  Created by Adam Iser on Sat Jul 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AIStatusSelectionView : NSView {
    AIAdium				*owner;

    IBOutlet	NSView			*view_contents;
    IBOutlet	NSPopUpButton		*popUp_status;

}

- (id)initWithFrame:(NSRect)frameRect owner:(id)inOwner;
- (IBAction)selectNewStatus:(id)sender;

@end
