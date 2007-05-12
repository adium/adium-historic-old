#import <Adium/AIPlugin.h>

@protocol AILibpurplePlugin <AIPlugin>
//Called when it's time for the libpurple part of the plugin to load
- (void)installLibpurplePlugin;
@end
