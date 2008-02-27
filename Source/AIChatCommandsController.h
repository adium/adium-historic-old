//
//  AIChatCommandsController.h
//  Adium
//
//  Created by Chloe Haney on 11/07/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIAccount.h>
#import "AIChat.h"
#import "AIWindowController.h"
#import "AIUtilities/AICompletingTextField.h"
#import "AIMetaContact.h"

@interface AIChatCommandsController : AIWindowController 
{
	IBOutlet				id								sheet;
	IBOutlet				id								label_target;
	IBOutlet				id								label_comment;
	IBOutlet				AICompletingTextField			*textField_target;
	IBOutlet				NSTextField						*textField_comment;
							id								delegate;
							NSMutableDictionary				*parameters;
							NSMutableString					*nibToLoad;
							AIChatCommandsController *newChatCommandsController;

}

-(void)verifyCommand:(NSString*)command forChat:(AIChat*)chat;
-(id)delegate;
-(void)setDelegate:(id)newDelegate;
-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

@end

@interface NSObject (AIChatCommandsControllerDelegate)
- (void)executeCommandWithParameters:(NSDictionary *)paramters;
@end

