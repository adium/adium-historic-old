//
//  AIMTOC2ChatInviteWindowController.h
//  Adium
//
//  Created by Adam Iser on Fri Aug 15 2003.
//

@class AIHandle, AIMTOC2Account;

@interface AIMTOC2ChatInviteWindowController : NSWindowController {
    IBOutlet	NSTextView	*textView_prompt;
    IBOutlet	NSScrollView	*scrollView_prompt;
    
    AIHandle		*handle;
    NSString		*chatID;
    NSString		*chatName;
    AIMTOC2Account	*account;
    
}

+ (id)chatInviteFrom:(AIHandle *)inHandle forChatID:(NSString *)inChatID name:(NSString *)inChatName account:(AIMTOC2Account *)inAccount;
- (IBAction)accept:(id)sender;
- (IBAction)decline:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end
