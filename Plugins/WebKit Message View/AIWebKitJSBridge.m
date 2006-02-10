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

#import "AIWebKitJSBridge.h"


@implementation AIWebKitJSBridge
+ (AIWebKitJSBridge *) bridgeWithController:(AIWebKitMessageViewController *)c
{
	return [[[self alloc] initWithController:c] autorelease];
}

- (id) initWithController:(AIWebKitMessageViewController *)c
{
	if((self = [super init]))
	{
		controller = c;
	}
	return self;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return YES; //when we add js-accessible methods, this will need to be changed
}

/*
 This method returns the name to be used in the scripting environment for the selector specified by aSelector. It is your responsibility to ensure that the returned name is unique to the script invoking this method. If this method returns nil or you do not implement it, the default name for the selector will be constructed as follows:
 
 Any colon (“:”)in the Objective-C selector is replaced by an underscore (“_”).
 Any underscore in the Objective-C selector is prefixed with a dollar sign (“$”).
 Any dollar sign in the Objective-C selector is prefixed with another dollar sign.
*/
+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	return @"";
}
@end
