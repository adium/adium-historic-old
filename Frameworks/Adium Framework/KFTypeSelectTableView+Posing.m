//
//  KFTypeSelectTableView+Posing.m
//  AIUtilities.framework
//
//  Created by Ken Ferry on 3/3/05.
//  Copyright 2005 Ken Ferry. All rights reserved.
//

#import "KFTypeSelectTableView+Posing.h"

@implementation KFTypeSelectTableView (Posing)

+ (void)load
{
    [[KFTypeSelectTableView class] poseAsClass:[NSTableView class]];
}


@end
