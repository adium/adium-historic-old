#import <Cocoa/Cocoa.h>
#import "AIAdium.h"

@interface LNStatusIcon : NSObject <AIListObjectLeftView> {

    NSArray	*imageArray;


    float	maxWidth;

}


+ (id)statusIcon;


- (void)drawInRect:(NSRect)inRect;
- (float)widthForHeight:(int)inHeight;
- (void)setImageArray:(NSArray *)inImageArray;

@end
