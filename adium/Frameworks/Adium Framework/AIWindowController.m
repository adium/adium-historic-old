//
//  AIWindowController.m
//  Adium XCode
//
//  Created by Adam Iser on Sun Dec 14 2003.
//

#import "AIWindowController.h"


@implementation AIWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    adium = [AIObject sharedAdiumInstance];
    return([super initWithWindowNibName:windowNibName]);
}

@end
