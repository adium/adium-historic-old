//
//  AIColorSelectionPopUpButton.h
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//

/*!
 * @class AIColorSelectionPopUpButton
 * @brief Button for selecting colors
 *
 * Button which draws as a rectangle, with an inset of a selected color, and which displays the standard color picker when clicked, updating its color as colors are changed in the color picker.
 */
@interface AIColorSelectionPopUpButton : NSPopUpButton {
    NSArray	*availableColors;
    NSColor	*customColor;

    NSMenuItem	*customMenuItem;
}

/*!
 * @brief Set the available pre-set color choices
 *
 * Set the available pre-set color choices.  <b>inColors</b> should be alternating labels and colors (NSString, NSColor, NSString, NSColor, NSString, ...)
 * @param inColors An <tt>NSArray</tt> of color choics as described above
 */
- (void)setAvailableColors:(NSArray *)inColors;

/*!
 * @brief Set the selected color
 *
 * Set the selected color
 * @param inColor An <tt>NSColor</tt> of the new selected color
 */
- (void)setColor:(NSColor *)inColor;

/*!
 * @brief The currently selected color
 *
 * Returns the currently selected color.
 * @return An <tt>NSColor</tt> of the currently selected color
 */
- (NSColor *)color;

@end
