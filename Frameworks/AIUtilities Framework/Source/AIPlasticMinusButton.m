//
//  AIPlasticMinusButton.m
//  Adium
//
//  Created by Adam Iser on 8/9/04.
//

#import "AIPlasticMinusButton.h"
#import "AIImageAdditions.h"

@implementation AIPlasticMinusButton

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self setImage:[NSImage imageNamed:@"minus" forClass:[self class]]];
	}
	return self;    
}

@end
