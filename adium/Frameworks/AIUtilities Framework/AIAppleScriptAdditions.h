//
//  AIAppleScriptAdditions.h
//  Adium
//
//  Created by Adam Iser on Mon Feb 16 2004.
//

@interface NSAppleScript (AIAppleScriptAdditions)

- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo;

@end
