//
//  ESImageViewWithImagePicker.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 06 2004.

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
 * @param picker The <tt>ESImageViewWithImagePicker</tt> which changed
 * @param image An <tt>NSImage</tt> of the new image
 */
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)picker didChangeToImage:(NSImage *)image;

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

/*!
 * @class ESImageViewWithImagePicker
 * @brief Image view which displays and uses the Image Picker used by Apple Address Book and iChat when activated and also allows other image-setting behaviors.
 *
 * <p><tt>ESImageViewWithImagePicker</tt> is an  NSImageView subclass which supports:
 * - Address book-style image picker on double-click or enter, with delegate notification
 * - Copying, cutting, and pasting, with delegate notification
 * - Drag and drop into and out of the image well, with delegate notification
 * - Notifcation to the delegate of user's attempt to delete the image</p>
 * <p>It is therefore most useful with a delegate.  All delegate methods are optional; see the <tt>ESImageViewWithImagePickerDelegate</tt> protocol description.</p>
 * <p>Note: ESImageViewWithImagePicker requires Panther or better for the Address book-style image picker to work.</p>
 */
@interface ESImageViewWithImagePicker : NSImageView {
	NSImagePickerController *pickerController;
	NSString				*title;
	
	BOOL					useNSImagePickerController;
	IBOutlet	id			delegate;
	
	BOOL					shouldDrawFocusRing;
	NSResponder				*lastResp;
}

/*!
 * @brief Set the delegate
 *
 * Set the delegate.  See <tt>ESImageViewWithImagePickerDelegate</tt> protocol discussion for details.
 * @param inDelegate The delegate, which may implement any of the methods described in <tt>ESImageViewWithImagePickerDelegate</tt>.
*/ 
- (void)setDelegate:(id)inDelegate;

/*!
 * @brief Return the delegate
 *
 * Return the delegate.
 * @return The delegate
*/ 
- (id)delegate;

/*!
 * @brief Set the title of the Image Picker
 *
 * Set the title of the Image Picker window which will be displayed if the user activates it (see class discussion).
 * @param inTitle An <tt>NSString</tt> of the title
*/ 
- (void)setTitle:(NSString *)inTitle;

@end
