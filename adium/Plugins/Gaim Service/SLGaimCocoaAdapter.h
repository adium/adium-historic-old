//
//  SLGaimCocoaAdapter.h
//  Adium
//  Adapts gaim to the Cocoa event loop.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//


@protocol GaimThread
- (void)makeAccount:(id)account performSelector:(SEL)selector;
- (void)makeAccount:(id)account performSelector:(SEL)selector withObject:(id)object;
- (void)makeAccount:(id)account performSelector:(SEL)selector withObject:(id)firstObject withObject:(id)secondObject;
@end

/*!
 * @class SLGaimCocoaAdapter
 * Singleton to run libgaim from a Cocoa event loop.
 * You just need to do one <tt>[[SLGaimCocoaAdapter alloc] init]</tt>
 * where you initialize the gaim core and gaim will be its events
 * from Cocoa.
 **/
@interface SLGaimCocoaAdapter : NSObject<GaimThread> {
}

+ (void)createThreadedGaimCocoaAdapter:(NSArray *)portArray;
- (void)makeAccount:(id)account performSelector:(SEL)selector;
- (void)makeAccount:(id)account performSelector:(SEL)selector withObject:(id)object;
- (void)makeAccount:(id)account performSelector:(SEL)selector withObject:(id)firstObject withObject:(id)secondObject;

@end
