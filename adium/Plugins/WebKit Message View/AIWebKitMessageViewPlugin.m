
#import "AIWebKitMessageViewPlugin.h"
#import "AIWebKitMessageViewController.h"

#define WEBKIT_DEFAULT_PREFS	@"WebKit Defaults"

@implementation AIWebKitMessageViewPlugin

- (void)installPlugin
{
	//Register our default preferences and install our preference view
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
//    preferences = [[AISMPreferences preferencePane] retain];
	
	//Set up a time stamp format based on this user's locale
    NSString    *format = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT];
    if(!format || [format length] == 0){
        [[adium preferenceController] setPreference:[NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO]
                                             forKey:KEY_WEBKIT_TIME_STAMP_FORMAT
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
    }
	
    //Register ourself as a message view plugin
    [[adium interfaceController] registerMessageViewPlugin:self];
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat]);
}

@end
