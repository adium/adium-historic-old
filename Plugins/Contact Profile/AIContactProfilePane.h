//
//  AIContactProfilePane.h
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface AIContactProfilePane : AIContactInfoPane <AIListObjectObserver> {
	IBOutlet		AILinkTextView			*textView_profile;
	IBOutlet		AILinkTextView			*textView_status;

	AIListObject						*listObject;
	
	BOOL								viewIsOpen;
}

- (void)updatePane;
- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView;

@end
