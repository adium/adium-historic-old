//
//  AIAliasSupportPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Aug 18 2003.
//

#import "AIAliasSupportPreferences.h"
#import "AIAliasSupportPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

#define DISPLAYFORMAT_PREF_TITLE	@"Contact Display Formatting"
#define DISPLAYFORMAT_PREF_NIB		@"DisplayFormatPreferences"

@interface AIAliasSupportPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (NSMutableAttributedString *)colorKeyWords:(NSString *)theString;
@end

@implementation AIAliasSupportPreferences
+ (AIAliasSupportPreferences *)displayFormatPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//private
//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:DISPLAYFORMAT_PREF_TITLE]];

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

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Alias"
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:DISPLAY_NAME];
    [choicesMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Alias (Screen Name)"
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:DISPLAY_NAME_SCREEN_NAME];
    [choicesMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Screen Name (Alias)"
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:SCREEN_NAME_DISPLAY_NAME];
    [choicesMenu addItem:menuItem];

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Screen Name"
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:SCREEN_NAME];
    [choicesMenu addItem:menuItem];
    [format_menu setMenu:choicesMenu];

    [format_menu selectItemAtIndex:[format_menu indexOfItemWithTag:[[[owner preferenceController] preferenceForKey:@"Long Display Format" group:PREF_GROUP_DISPLAYFORMAT object:nil] intValue]]];

}

-(IBAction)changeFormat:(id) sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]] forKey:@"Long Display Format" group:PREF_GROUP_DISPLAYFORMAT object:nil];
}

- (void)dealloc
{
    [owner release];
    [super dealloc];
}

@end
