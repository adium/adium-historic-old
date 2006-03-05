#import "AIPlugin.h"

@protocol AILibgaimPlugin <AIPlugin>
//The path at which one or more libgaim plugins (.so files) can be found for this plugin
- (NSString *)libgaimPluginPath;
@end
