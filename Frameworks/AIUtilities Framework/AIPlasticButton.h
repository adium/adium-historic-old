//
//  AIPlasticButton.h
//  Adium
//
//  Created by Adam Iser on Thu Jun 26 2003.
//

/*!
	@class AIPlasticButton
	@abstract Abstract NSButton subclass for implementing a "plastic" Aqua button with a given image
	@discussion <tt>AIPlasticButton</tt> must be subclassed to call -[self setImage:] with the image to be displayed, in initWithFrame: method. It will then display a "plastic" Aqua button within its frame, with the designated image centered within the button.
*/
@interface AIPlasticButton : NSButton {

    NSImage	*plasticCaps;
    NSImage	*plasticMiddle;
    NSImage	*plasticPressedCaps;
    NSImage	*plasticPressedMiddle;
    NSImage	*plasticDefaultCaps;
    NSImage	*plasticDefaultMiddle;
}



@end
