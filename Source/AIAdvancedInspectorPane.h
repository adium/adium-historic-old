//
//  AIAdvancedInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIListObject.h>

@interface AIAdvancedInspectorPane : AIObject {

}
-(NSString *)nibName;
-(void)updateForListObject:(AIListObject *)inObject;
@end
