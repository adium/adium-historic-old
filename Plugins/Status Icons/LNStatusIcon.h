
@interface LNStatusIcon : NSObject <AIListObjectView> {

    NSArray	*imageArray;


    float	maxWidth;

}


+ (id)statusIcon;


- (void)drawInRect:(NSRect)inRect;
- (float)widthForHeight:(int)inHeight;
- (void)setImageArray:(NSArray *)inImageArray;

@end
