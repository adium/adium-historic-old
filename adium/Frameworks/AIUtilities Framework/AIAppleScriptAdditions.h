//
//  AIAppleScriptAdditions.h
//  Adium XCode
//
//  Created by Adam Iser on Mon Feb 16 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface NSAppleScript (AIAppleScriptAdditions)

- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo;

@end
