//
//  ESContactListDisplayFormatPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Aug 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESContactListDisplayFormatPreferences.h"
#import "ESContactListDisplayFormatPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define DISPLAYFORMAT_PREF_TITLE	@"Contact Display Formatting"
#define DISPLAYFORMAT_PREF_NIB		@"ContactListDisplayFormat"

@interface ESContactListDisplayFormatPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (NSMutableAttributedString *)colorKeyWords:(NSString *)theString;
@end

@implementation ESContactListDisplayFormatPreferences

+ (ESContactListDisplayFormatPreferences *)contactListDisplayFormatPreferencesWithOwner:(id)inOwner
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

    displayFormat = [[owner preferenceController] preferenceForKey:@"Format String" group:PREF_GROUP_DISPLAYFORMAT object:nil];
    
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

- (IBAction)setDisplayFormat:(id)sender
{
    displayFormat = [[textField_displayFormat textStorage] string];

    //Save the displayFormat
    [[owner preferenceController] setPreference:displayFormat forKey:@"Format String" group:PREF_GROUP_DISPLAYFORMAT object:nil];

//    [self updateScanner];
}

- (void)configureView
{
    [[textField_displayFormat textStorage] setAttributedString:[self colorKeyWords:displayFormat]];
}

- (void)dealloc
{
    [owner release];
    [super dealloc];
}

- (NSMutableAttributedString *)colorKeyWords:(NSString *)theString
{
    NSMutableAttributedString	*attribString;
    NSScanner			*colorKeyWordScanner;
    NSString			*keyWord;

    NSParameterAssert(theString != nil);

    //color the string
    attribString = [[NSMutableAttributedString alloc] initWithString:theString];
    colorKeyWordScanner = [NSScanner scannerWithString:theString];
    while(![colorKeyWordScanner isAtEnd]){
        [colorKeyWordScanner scanUpToString:@"<" intoString:nil];
        if([colorKeyWordScanner scanUpToString:@">" intoString:&keyWord]){
            [attribString addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedRed:0.647 green:0.741 blue:0.839 alpha:1.0] range:NSMakeRange([colorKeyWordScanner scanLocation] - [keyWord length],[keyWord length]+1)];
        }
    }

    return attribString;
}


- (void)textDidChange:(NSNotification *)aNotification
{
    [self setDisplayFormat:nil];
}
/*
 - (void)configurePreferenceViewController:(AIPreferenceViewController *)inController
 {
     //Fill in the current displayFormat
     //   if(displayFormat){
     /*    }else{
     [[textField_displayFormat textStorage] setStringValue:@""];
     }
 } */



@end
