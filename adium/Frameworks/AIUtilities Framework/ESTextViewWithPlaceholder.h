//
//  ESTextViewWithPlaceholder.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Dec 26 2003.


@interface ESTextViewWithPlaceholder : NSTextView {
    NSString *placeholder;
}

-(void)setPlaceholder:(NSString *)inPlaceholder;
-(NSString *)placeholder;

@end
