//
//  AIContactProfilePane.h
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//

@interface AIContactProfilePane : AIContactInfoPane <AIListObjectObserver> {
	IBOutlet		NSTextView			*textView_profile;
	IBOutlet		NSTextView			*textView_status;

	AIListObject						*listObject;
	
	BOOL								viewIsOpen;
}

- (void)updatePane;
- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView;

@end
