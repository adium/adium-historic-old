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
}

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

- (void)setTitle:(NSString *)inTitle;
@end
