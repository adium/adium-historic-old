//
//  ESTextViewWithPlaceholder.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Dec 26 2003.
//

#import "ESTextViewWithPlaceholder.h"


@implementation ESTextViewWithPlaceholder

-(void)setPlaceholder:(NSString *)inPlaceholder
{
    [placeholder release];
    placeholder = [inPlaceholder copy];
    
    if ([[self string] isEqualToString:@""]){
        [self setString:placeholder];
        [self setTextColor:[NSColor disabledControlTextColor]];
    }
}

-(NSString *)placeholder
{
    return placeholder;
}

- (BOOL)becomeFirstResponder
{
    BOOL shouldBecomeFirstResponder;
    if (shouldBecomeFirstResponder = [super becomeFirstResponder]){
        if ([[self string] isEqualToString:placeholder]){
            [self setString:@""];
            [self setTextColor:[NSColor blackColor]];
        }
    }
    return shouldBecomeFirstResponder;
}
- (BOOL)resignFirstResponder
{
    BOOL shouldResignFirstResponder;
    if (shouldResignFirstResponder = [super resignFirstResponder]){
        if ([[self string] isEqualToString:@""]){
            [self setString:placeholder];
            [self setTextColor:[NSColor disabledControlTextColor]];
        }
    }
    return shouldResignFirstResponder;
}
@end
