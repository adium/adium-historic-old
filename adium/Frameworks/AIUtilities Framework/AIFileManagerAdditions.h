//
//  AIFileManagerAdditions.h
//  Adium XCode
//
//  Created by Adam Iser on Tue Dec 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (AIFileManagerAdditions)
- (BOOL)trashFileAtPath:(NSString *)sourcePath;
@end
