//
//  SLGaimCocoaAdapter.h
//  Adium
//  Adapts gaim to the Cocoa event loop.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//

/*!
 * @class SLGaimCocoaAdapter
 * Singleton to run libgaim from a Cocoa event loop.
 * You just need to do one <tt>[[SLGaimCocoaAdapter alloc] init]</tt>
 * where you initialize the gaim core and gaim will be its events
 * from Cocoa.
 **/
@interface SLGaimCocoaAdapter : NSObject {
}

@end
