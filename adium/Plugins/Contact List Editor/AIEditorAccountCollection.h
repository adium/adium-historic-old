//
//  AIEditorAccountCollection.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIEditorCollection.h"

@class AIAccount, AIEditorListGroup, AIEditorAccountCollection;
@protocol AIAccount_Handles;

@interface AIEditorAccountCollection : NSObject <AIEditorCollection> {
    AIAccount<AIAccount_Handles>	*account;
    AIEditorListGroup			*list;
    
}

+ (AIEditorAccountCollection *)editorCollectionForAccount:(AIAccount *)inAccount;
- (id)initForAccount:(AIAccount *)inAccount;
- (NSString *)name;
- (NSImage *)icon;
- (BOOL)enabled;
- (AIEditorListGroup *)list;
                
@end
