#import "CBHandleURLScriptCommand.h"

@implementation CBHandleURLScriptCommand

- (id)performDefaultImplementation
{
	NSString *commandName = [[self commandDescription] commandName];
	NSString *urlString = [self directParameter];
	
	if([commandName isEqualToString:@"GetURL"] || [commandName isEqualToString:@"OpenURL"]){
		NSLog(urlString);
	}
    
    return nil;
} 

@end