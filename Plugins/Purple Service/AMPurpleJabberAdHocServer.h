#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <AdiumLibpurple/PurpleCommon.h>
#include "xmlnode.h"

@class ESPurpleJabberAccount, AMPurpleJabberAdHocServer, AMPurpleJabberFormGenerator;

enum AMPurpleJabberAdHocCommandStatus {
	executing,
	canceled,
	completed
};

enum AMPurpleJabberAdHocCommandNoteType {
	error,
	info,
	warn
};

@interface AMPurpleJabberAdHocCommand : AIObject {
	AMPurpleJabberAdHocServer *server;
	NSString *jid;
	NSString *node;
	NSString *iqid;
	NSString *sessionid;
	
	xmlnode *command;
}

- (id)initWithServer:(AMPurpleJabberAdHocServer*)_server command:(xmlnode*)_command jid:(NSString*)_jid iqid:(NSString*)_iqid;

- (AMPurpleJabberFormGenerator*)form;
- (NSString*)jid;
- (NSString*)sessionid;

- (void)setSessionid:(NSString*)_sessionid; /* this can be used by the AMPurpleJabberAdHocServerDelegate for tracking the specific session */

/* actions is an NSArray of NSStrings, which can be any combination of @"execute", @"cancel", @"prev", @"next", @"complete" */
- (AMPurpleJabberAdHocCommand*)generateReplyWithForm:(AMPurpleJabberFormGenerator*)form actions:(NSArray*)actions defaultAction:(unsigned)defaultAction status:(enum AMPurpleJabberAdHocCommandStatus)status;
- (AMPurpleJabberAdHocCommand*)generateReplyWithNote:(NSString*)text type:(enum AMPurpleJabberAdHocCommandNoteType)type status:(enum AMPurpleJabberAdHocCommandStatus)status;

- (void)send;

@end

@interface AMPurpleJabberAdHocServer : AIObject {
	ESPurpleJabberAccount *account;
	NSMutableDictionary *commands;
}

- (id)initWithAccount:(ESPurpleJabberAccount*)_account;

- (void)addCommand:(NSString*)node delegate:(id)delegate name:(NSString*)name;

- (ESPurpleJabberAccount*)account;

@end

@interface NSObject (AMPurpleJabberAdHocServerDelegate)

- (void)adHocServer:(AMPurpleJabberAdHocServer*)server executeCommand:(AMPurpleJabberAdHocCommand*)command;

@end

@interface AMPurpleJabberAdHocPing : AIObject {
}

+ (void)adHocServer:(AMPurpleJabberAdHocServer*)server executeCommand:(AMPurpleJabberAdHocCommand*)command;

@end
