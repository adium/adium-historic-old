//
//  AIListObject.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIMutableOwnerArray, AIListGroup;

@interface AIListObject : NSObject {
    NSMutableDictionary	*displayDictionary;	//A dictionary of values affecting this object's display
    AIListGroup 	*containingGroup;	//The group this object is in
    NSString		*UID;
    
}

- (id)initWithUID:(NSString *)inUID;

//Identifying information
- (NSString *)UID;

//Display
- (NSString *)displayName;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;

//Nesting
- (void)setContainingGroup:(AIListGroup *)inGroup;
- (AIListGroup *)containingGroup;

@end
