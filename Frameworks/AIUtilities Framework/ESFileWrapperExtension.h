//
//  ESFileWrapperExtension.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 10 2004.
//

@interface ESFileWrapperExtension : NSFileWrapper {
	NSString	*originalPath;
}

- (NSString *)originalPath;

@end
