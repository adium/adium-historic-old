//
//  ESFloater.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.
//

#import <Foundation/Foundation.h>
#import "ESStaticView.h"

@interface ESFloater : NSObject {
    ESStaticView	*staticView;
    NSPanel		*panel;
    BOOL                windowIsVisible;
    NSTimer             *visibilityTimer;
    float               maxOpacity;
}

+ (id)floaterWithImage:(NSImage *)inImage frame:(BOOL)frame;
- (void)moveFloaterToPoint:(NSPoint)inPoint;
- (IBAction)close:(id)sender;
- (void)endFloater;
- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;
- (void)setVisible:(BOOL)inVisible animate:(BOOL)animate;
- (void)setMaxOpacity:(float)inMaxOpacity;

@end
