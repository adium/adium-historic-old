//
//  AIStatusSelectionView.h
//  Adium
//
//  Created by Adam Iser on Sat Jul 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface AIStatusSelectionView : NSView {
    AIAdium				*adium;

    IBOutlet	NSView			*view_contents;
    IBOutlet	NSPopUpButton		*popUp_status;
}

- (id)initWithFrame:(NSRect)frameRect;
- (IBAction)selectNewStatus:(id)sender;

@end
