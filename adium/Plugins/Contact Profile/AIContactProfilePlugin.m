//
//  AIContactInfoPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//

#import "AIContactProfilePlugin.h"
#import "AIContactProfilePane.h"

@implementation AIContactProfilePlugin

- (void)installPlugin
{
	[AIContactProfilePane contactInfoPane];
}

@end
