//
//  AIServiceMenu.h
//  Adium
//
//  Created by Adam Iser on 5/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIObject.h>

@interface AIServiceMenu : AIObject {

}

+ (NSMenu *)menuOfServicesWithTarget:(id)target activeServicesOnly:(BOOL)activeServicesOnly
					 longDescription:(BOOL)longDescription format:(NSString *)format;

@end
