/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactProfilePane.h"
#import "AIContentController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AILinkTextView.h>
#import <AIUtilities/AITextAttributes.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AILocalizationTextField.h>

/*!
 * @class AIContactProfilePane
 * @brief Pane for contact info and profile
 *
 * Man, this is ugly.
 */
@implementation AIContactProfilePane

/*!
 * @brief Category
 */
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return AIInfo_Profile;
}
/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"ContactProfilePane";
}

//Configure the preference view
- (void)viewDidLoad
{
	viewIsOpen = YES;
	
	[label_status setLocalizedString:AILocalizedString(@"Status",nil)];
	[label_profileIfAvailable setLocalizedString:AILocalizedString(@"Profile (if available):",nil)];

    [[adium contactController] registerListObjectObserver:self];
}

//Preference view is closing
- (void)viewWillClose
{
	viewIsOpen = NO;
    [[adium contactController] unregisterListObjectObserver:self];
	[listObject release]; listObject = nil;
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	//New list object
	if (inObject != listObject) {
		[listObject release];
		listObject = [inObject retain];
	}
	
	//Display what we have now
	[self updatePane];
	
	//Refresh the window's content (Contacts only)
	if ([listObject isKindOfClass:[AIListContact class]]) {
		[[adium contactController] updateListContactStatus:(AIListContact *)listObject];
	}
}

//Refresh if changes are made to the object we're displaying
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if (inObject == listObject) {
        [self updatePane];
    }
    return nil;
}

//Update our pane to reflect our contact
- (void)updatePane
{	
	//Text Profile
	[[adium contentController] filterAttributedString:([listObject isKindOfClass:[AIListContact class]] ?
													   [(AIListContact *)listObject profile] :
													   nil)
									  usingFilterType:AIFilterDisplay
											direction:AIFilterIncoming
										filterContext:listObject
									  notifyingTarget:self
											 selector:@selector(gotFilteredProfile:context:)
											  context:listObject];
	//Away & Status
	[[adium contentController] filterAttributedString:[listObject statusMessage]
									  usingFilterType:AIFilterDisplay
											direction:AIFilterIncoming
										filterContext:listObject
									  notifyingTarget:self
											 selector:@selector(gotFilteredStatus:context:)
											  context:listObject];
}

- (void)gotFilteredProfile:(NSAttributedString *)infoString context:(AIListObject *)object
{
	if (viewIsOpen)
		[self setAttributedString:infoString intoTextView:textView_profile];
}

- (void)gotFilteredStatus:(NSAttributedString *)infoString context:(AIListObject *)object
{
	if (viewIsOpen)
		[self setAttributedString:infoString intoTextView:textView_status];
}

//
- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView
{
	NSColor		*backgroundColor = nil;

	if (infoString && [infoString length]) {
		[[textView textStorage] setAttributedString:infoString];	
		backgroundColor = [infoString attribute:AIBodyColorAttributeName
										atIndex:0 
						  longestEffectiveRange:nil 
										inRange:NSMakeRange(0,[infoString length])];
	} else {
		[[textView textStorage] setAttributedString:[NSAttributedString stringWithString:@""]];	
	}
	[textView setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView];
}


@end
