//
//  AIColorSelectionPopUpButton.h
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//

@interface AIColorSelectionPopUpButton : NSPopUpButton {
    NSArray	*availableColors;
    NSColor	*customColor;

    NSMenuItem	*customMenuItem;
}

- (void)setAvailableColors:(NSArray *)inColors;
- (void)setColor:(NSColor *)inColor;
- (NSColor *)color;

@end
