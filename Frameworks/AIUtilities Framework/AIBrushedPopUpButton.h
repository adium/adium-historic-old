//
//  AIBrushedPopUpButton.h
//  Adium
//
//  Created by Adam Iser on Fri Jul 11 2003.
//

@interface AIBrushedPopUpButton : NSPopUpButton {
    NSImage		*popUpRolloverCaps;
    NSImage		*popUpRolloverMiddle;
    NSImage		*popUpPressedCaps;
    NSImage		*popUpPressedMiddle;
    NSImage		*popUpTriangle;
    NSImage		*popUpTriangleWhite;

    BOOL 		mouseIn;
    NSTrackingRectTag 	trackingTag;

    NSString		*popUpTitle;
}

@end
