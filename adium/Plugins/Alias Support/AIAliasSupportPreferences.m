//
//  AIAliasSupportPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Aug 18 2003.
//

#import "AIAliasSupportPreferences.h"
#import "AIAliasSupportPlugin.h"

#define DISPLAYFORMAT_PREF_TITLE	AILocalizedString(@"Contact Display Formatting",nil)
#define DISPLAYFORMAT_PREF_NIB		@"DisplayFormatPreferences"

#define ALIAS   AILocalizedString(@"Alias",nil)
#define ALIAS_SCREENNAME   AILocalizedString(@"Alias (Screen Name)",nil)
#define SCREENNAME_ALIAS   AILocalizedString(@"Screen Name (Alias)",nil)
#define SCREENNAME   AILocalizedString(@"Screen Name",nil)

@interface AIAliasSupportPreferences (PRIVATE)
- (void)configureView;
- (NSMutableAttributedString *)colorKeyWords:(NSString *)theString;
@end

@implementation AIAliasSupportPreferences
+ (AIAliasSupportPreferences *)displayFormatPreferences
{
    return([[[self alloc] init] autorelease]);
}

//private
//init
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:DISPLAYFORMAT_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:DISPLAYFORMAT_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;

}

- (void)configureView
{
    NSMenu		*choicesMenu = [[NSMenu alloc] init];
    NSMenuItem		*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:ALIAS
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:DISPLAY_NAME];
    [choicesMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:ALIAS_SCREENNAME
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:DISPLAY_NAME_SCREEN_NAME];
    [choicesMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:SCREENNAME_ALIAS
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:SCREEN_NAME_DISPLAY_NAME];
    [choicesMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:SCREENNAME
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:SCREEN_NAME];
    [choicesMenu addItem:menuItem];

    [format_menu setMenu:choicesMenu];
    [format_menu selectItemAtIndex:[format_menu indexOfItemWithTag:[[[[adium preferenceController] preferencesForGroup:PREF_GROUP_DISPLAYFORMAT] objectForKey:@"Long Display Format"] intValue]]];
}

-(IBAction)changeFormat:(id) sender
{
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]] forKey:@"Long Display Format" group:PREF_GROUP_DISPLAYFORMAT];
}

- (void)dealloc
{
    [super dealloc];
}

@end
