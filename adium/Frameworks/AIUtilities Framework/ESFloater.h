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
}
+ (id)floaterWithImage:(NSImage *)inImage at:(NSPoint)inPoint;
- (void)moveFloaterToPoint:(NSPoint)inPoint;
- (IBAction)close:(id)sender;
- (void)endFloater;
- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;
@end
