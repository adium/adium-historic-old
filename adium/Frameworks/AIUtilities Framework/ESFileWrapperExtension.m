//
//  ESFileWrapperExtension.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 10 2004.
//

#import "ESFileWrapperExtension.h"

@implementation ESFileWrapperExtension

- (id)initWithPath:(NSString *)path
{
	originalPath = [path retain];
	
	return ([super initWithPath:path]);
}

- (BOOL)updateFromPath:(NSString *)path
{
	if (originalPath != path){
		[originalPath release]; originalPath = [path retain];
	}
	
	return ([super updateFromPath:path]);
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomicFlag updateFilenames:(BOOL)updateNamesFlag
{
	if (updateNamesFlag){
		if (originalPath != path){
			[originalPath release]; originalPath = [path retain];
		}
	}
	
	return ([super writeToFile:path atomically:atomicFlag updateFilenames:updateNamesFlag]);
}

- (NSString *)originalPath
{
	return originalPath;
}

@end
