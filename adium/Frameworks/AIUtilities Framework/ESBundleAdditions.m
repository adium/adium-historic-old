//
//  ESBundleAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//

#import "ESBundleAdditions.h"

@implementation NSBundle (ESBundleAdditions)

- (NSString *)name
{
	NSDictionary	*info = [self localizedInfoDictionary];
	NSString		*label = [info objectForKey:@"CFBundleName"];
	
	if (!label){
		label = [self objectForInfoDictionaryKey:@"CFBundleName"];
	}
	
	if (!label){
		label = [self bundleIdentifier];
	}
	
	return label;
}

@end
