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

#import "AIPreferenceController.h"
#import "AINotifyTypingPlugin.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <AppKit/NSAccessibility.h>

@interface AINotifyTypingPlugin (PRIVATE)
-(void)updateStatus:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end

@implementation AINotifyTypingPlugin

NSString *AppleSynthesisAttribute = @"AppleSynthesis";

- (void)installPlugin
{
}

- (void)uninstallPlugin
{

}

- (void)dealloc
{
	[super dealloc];
}

- (NSArray *)accessibilityAttributeNames 
{
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityValueAttribute, AppleSynthesisAttribute, nil]] retain];
    }
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute 
{
	NSArray		*commands;
	AITypingState typingState;
	message = [[object messageString];

	if ([[commands objectAtIndex:1] isEqualToString:@"on"]) {
		typingState = AITyping;
				
	} else if ([[commands objectAtIndex:1] isEqualToString:@"entered"]) {
		typingState = AIEnteredText;
		
	} else {
		typingState = AINotTyping;
		
//  return @"Typing Notification";

	
	return [super accessibilityAttributeValue:attribute];
}

@end
