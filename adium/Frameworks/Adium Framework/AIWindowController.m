//
//  AIWindowController.m
//  Adium XCode
//
//  Created by Adam Iser on Sun Dec 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIWindowController.h"


@implementation AIWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    adium = [AIObject sharedAdiumInstance];
    return([super initWithWindowNibName:windowNibName]);
}

@end
