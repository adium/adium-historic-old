//
//  AIEditorCollection.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIEditorListGroup, AIAccount;

@interface AIEditorCollection : NSObject {
    NSString 		*name;
    NSImage 		*icon;
    AIEditorListGroup 	*list;
    BOOL		enabled;
    AIAccount		*account;
    
}

- (id)initWithName:(NSString *)inName icon:(NSImage *)inIcon list:(AIEditorListGroup *)inList enabled:(BOOL)inEnabled forAccount:(AIAccount *)inAccount;
- (NSString *)name;
- (NSImage *)icon;
- (AIEditorListGroup *)list;
- (BOOL)enabled;
- (AIAccount *)account;

@end
