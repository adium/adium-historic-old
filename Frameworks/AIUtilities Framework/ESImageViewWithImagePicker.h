//
//  ESImageViewWithImagePicker.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 06 2004.

#import "NSImagePicker.h"

@class NSImagePickerController, ESImageViewWithImagePicker;
@class NSImage, NSString, NSResponder;

//Protocol merely for documentation purposes; delegate does not need to actually implement this protocol,
//and all methods are optional.
@protocol ESImageViewWithImagePickerDelegate
//The user selected an image in the image picker
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)picker didChangeToImage:(NSImage *)image;

//The user deleted the image from the image picker (via delete or cut, for example)
- (void)deleteInImageViewWithImagePicker:(ESImageViewWithImagePicker *)picker;

//The delegate is given the opporutinty to supply an image other than the NSImageView's image; if this method
//returns nil or is not implemented, the NSImageView's image is used.
- (NSImage *)imageForImageViewWithImagePicker:(ESImageViewWithImagePicker *)picker;
@end

@interface ESImageViewWithImagePicker : NSImageView {
	NSImagePickerController *pickerController;
	NSString				*title;
	
	BOOL					useNSImagePickerController;
	IBOutlet	id			delegate;
	
	BOOL					shouldDrawFocusRing;
	NSResponder				*lastResp;
}

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

- (void)setTitle:(NSString *)inTitle;

- (void)copy:(id)sender;
- (void)paste:(id)sender;
@end
