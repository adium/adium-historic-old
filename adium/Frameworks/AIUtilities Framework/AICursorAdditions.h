//
//  AICursorAdditions.h
//  Adium
//
//  Created by Adam Iser on Mon Apr 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSCursor (AICursorAdditions)
+ (NSCursor *)openGrabHandCursor;
+ (NSCursor *)closedGrabHandCursor;
+ (NSCursor *)handPointCursor;

@end
