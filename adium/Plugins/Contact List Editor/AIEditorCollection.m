//
//  AIEditorCollection.m
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorCollection.h"
#import "AIEditorListGroup.h"
#import <Adium/Adium.h>

@implementation AIEditorCollection

- (id)initWithName:(NSString *)inName icon:(NSImage *)inIcon list:(AIEditorListGroup *)inList enabled:(BOOL)inEnabled forAccount:(AIAccount *)inAccount
{
    [super init];

    name = [inName retain];
    icon = [inIcon retain];
    list = [inList retain];
    enabled = inEnabled;
    account = [inAccount retain];
    
    return(self);
}

- (NSString *)name{
    return(name);
}
- (NSImage *)icon{
    return(icon);
}
- (AIEditorListGroup *)list{
    return(list);
}
- (BOOL)enabled{
    return(enabled);
}
- (AIAccount *)account{
    return(account);
}

@end
