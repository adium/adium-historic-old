//
//  ESFileTransferController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESFileTransferController.h"


@implementation ESFileTransferController
//init and close
- (void)initController
{

}

- (void)closeController
{
    
}

- (NSString *)saveLocationForFileName:(NSString *)inFile
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setTitle:@"Receive File"];
    
    [savePanel runModalForDirectory:nil file:inFile];
    
    return([savePanel filename]);
}


@end
