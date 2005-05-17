//
//  ESImageViewWithImagePicker.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 06 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@class NSImagePickerController, ESImageViewWithImagePicker;
@class NSImage, NSString, NSResponder;

/*!
 * @protocol ESImageViewWithImagePickerDelegate
 * @brief Delegate protocol for <tt>ESImageViewWithImagePicker</tt>
 *
 * Delegate protocol for <tt>ESImageViewWithImagePicker</tt>.  Implementation of all methods is optional.
 */
@protocol ESImageViewWithImagePickerDelegate
/*!
 * imageViewWithImagePicker:didChangeToImage:
 * @brief Notifies the delegate of a new image
 *
 * Notifies the delegate of a new image selected by the user (which may have been set in any of the ways explained in the class description).
 * This may not provide information as worthwhile as imageViewWithImagePicker:didChangeToImageData:, which is the recommended method to implement
 * @param picker The <tt>ESImageViewWithImagePicker</tt> which changed
 * @param image An <tt>NSImage</tt> of the new image
 */
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)picker didChangeToImage:(NSImage *)image;

/*!
 * imageViewWithImagePicker:didChangeToImageData:
 * @brief Notifies the delegate of a new image
 *
 * Notifies the delegate of a new image selected by the user (which may have been set in any of the ways explained in the class description).
 * @param picker The <tt>ESImageViewWithImagePicker</tt> which changed
 * @param image An <tt>NSData</tt> with data for the new image
 */
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)picker didChangeToImageData:(NSData *)imageData;

/*!
 *  deleteInImageViewWithImagePicker:
 * @brief Notifies the delegate of an attempt to delete the image
 *
 * Notifies the delegate of an attempt to delete the image.  This may occur by the user pressing delete with the image selected or by the user performing a Cut operation on it. Recommended behavior is to clear the image view or to replace the image with a default.
 * @param picker The <tt>ESImageViewWithImagePicker</tt> which changed
 */
- (void)deleteInImageViewWithImagePicker:(ESImageViewWithImagePicker *)picker;

/*!
 * imageForImageViewWithImagePicker:
 * @brief Requests the image to display in the Image Picker when it is displayed via user action
 *
 * By default, the Image Picker will use the same image as the <tt>ESImageViewWithImagePicker</tt> object does.  However, if the delegate wishes to supply a different image to be initially displayed in the Image Picker (for example, if a larger or higher resolution image is available), it may implement this method.  If this method returns nil, the imageView's own image will be used just as if the method were not implemented.
 * @param picker The <tt>ESImageViewWithImagePicker</tt> which will display the Image Picker
 * @return An <tt>NSImage</tt> to display in the Image Picker, or nil if the <tt>ESImageViewWithImagePicker</tt>'s own image should be used.
 */
- (NSImage *)imageForImageViewWithImagePicker:(ESImageViewWithImagePicker *)picker;
@end

@interface ESImageViewWithImagePicker : NSImageView {
	NSImagePickerController *pickerController;
	NSString				*title;
	
	BOOL					useNSImagePickerController;
	BOOL					imagePickerClassIsAvailable;

	IBOutlet	id			delegate;
	
	BOOL					shouldDrawFocusRing;
	NSResponder				*lastResp;
	
	NSPoint					mouseDownPos;
}

- (void)setDelegate:(id)inDelegate;
- (id)delegate;
- (void)setTitle:(NSString *)inTitle;
- (IBAction)showImagePicker:(id)sender;
- (void)setUseNSImagePickerController:(BOOL)inUseNSImagePickerController;

@end
