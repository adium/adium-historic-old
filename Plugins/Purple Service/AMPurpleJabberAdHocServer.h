#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

#import "ESPurpleJabberAccount.h"

@class AMPurpleJabberAdHocCommand;

@interface AMPurpleJabberAdHocServer : AIObject {
	ESPurpleJabberAccount *account;
	NSMutableDictionary *commands;
}

- (id)initWithAccount:(ESPurpleJabberAccount *)_account;
- (void)addCommand:(NSString *)node delegate:(id)delegate name:(NSString *)name;
- (ESPurpleJabberAccount *)account;

@end

@interface NSObject (AMPurpleJabberAdHocServerDelegate)
- (void)adHocServer:(AMPurpleJabberAdHocServer *)server executeCommand:(AMPurpleJabberAdHocCommand *)command;
@end

