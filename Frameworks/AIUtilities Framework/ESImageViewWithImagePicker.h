//
//  ESImageViewWithImagePicker.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 06 2004.

#import "NSImagePicker.h"

@interface ESImageViewWithImagePicker : NSImageView {
	NSImagePickerController *pickerController;
	NSString				*title;
	
	BOOL					useNSImagePickerController;
	IBOutlet	id			delegate;
	
	BOOL shouldDrawFocusRing;
	NSResponder *lastResp;
}

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

- (void)setTitle:(NSString *)inTitle;

- (void)copy:(id)sender;
- (void)paste:(id)sender;
@end
