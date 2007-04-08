#import "AIPlugin.h"

@protocol AILibgaimPlugin <AIPlugin>
//Called when it's time for the libgaim part of the plugin to load
- (void)installLibgaimPlugin;
@end
