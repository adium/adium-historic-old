//
//  AIContactProfilePane.h
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIContactProfilePane : AIContactInfoPane <AIListObjectObserver> {
	IBOutlet		NSTextView			*textView_profile;
	IBOutlet		NSTextView			*textView_status;

	AIListObject				*listObject;
}

- (void)updatePane;
- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView;

@end
