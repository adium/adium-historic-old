
@interface LNStatusIconsPreferences : AIObject {
    IBOutlet	NSView		*view_prefView;
    IBOutlet	NSButton	*checkBox_displayStatusIcons;
}

+ (LNStatusIconsPreferences *)statusIconsPreferences;
- (IBAction)changePreference:(id)sender;

@end
