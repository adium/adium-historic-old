
#define STATUS_ICONS_DEFAULT_PREFS	@"StatusIconsDefaults"
#define PREF_GROUP_STATUS_ICONS		@"StatusIcons"
#define KEY_DISPLAY_STATUS_ICONS	@"Display Status Icons"

@class LNStatusIconsPreferences;

@interface LNStatusIconsPlugin : AIPlugin <AIListObjectObserver> {


    LNStatusIconsPreferences 	*preferences;


    BOOL		displayStatusIcon;

    NSImage		*idleImage;
    NSImage		*awayImage;

}

@end
