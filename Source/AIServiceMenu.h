//
//  AIServiceMenu.h
//  Adium
//
//  Created by Adam Iser on 5/19/05.
//

#import <Adium/AIObject.h>

@class AIService;

@interface AIServiceMenu : AIObject {

}

+ (NSMenu *)menuOfServicesWithTarget:(id)target activeServicesOnly:(BOOL)activeServicesOnly
					 longDescription:(BOOL)longDescription format:(NSString *)format;

@end

@interface NSObject (AIServiceMenuTarget)
- (BOOL)serviceMenuShouldIncludeService:(AIService *)service;
@end
