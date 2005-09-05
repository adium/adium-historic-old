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

#import "SMLoggerContact.h"
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import "AIContactController.h"

@implementation SMLoggerContact
- (SMLoggerContact *)initWithIdentifier:(NSString *)inIdentifier service:(NSString *)inService dbIdentifier:(int)inDbIdentifier isAccount:(BOOL)isAccount {
	if ((self = [super init])) {
		identifier = [inIdentifier copy]; // -copy and -retain do the same thing for an immutable string, I think...
		service = [inService copy];
		dbIdentifier = inDbIdentifier;
		if (isAccount) {
			displayName = [identifier copy];
		}
		else {
			displayName = [[[adium contactController] existingListObjectWithUniqueID:[NSString stringWithFormat:@"%@.%@",service,identifier]] displayName]; // nil if there is no display name, but that's ok.
			displayName = [displayName copy];
		}
		serviceImage =  [[AIServiceIcons serviceIconForServiceID:service
															type:AIServiceIconSmall
													   direction:AIIconNormal] retain];
	}
	return self;
}

- (void)dealloc {
	[identifier release];
	[service release];
	[serviceImage release];
	[displayName release];
	[super dealloc];
}

- (int)dbIdentifier {
	return dbIdentifier;
}

- (NSString *)identifier {
	return identifier;
}

- (NSString *)service {
	return service;
}

- (NSString *)displayName {
	return displayName;
}

- (NSImage *)serviceImage {
	return serviceImage;
}
@end
