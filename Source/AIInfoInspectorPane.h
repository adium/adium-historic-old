//
//  AIInfoInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIContactInfoContentController.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIContactInfoImageViewWithImagePicker.h>;

@interface AIInfoInspectorPane : AIObject <AIContentInspectorPane, AIListObjectObserver> {	
	
			 AIListObject							*displayedObject;
	IBOutlet NSView									*inspectorContentView;

	IBOutlet AIContactInfoImageViewWithImagePicker	*userIcon;
	IBOutlet NSImageView							*statusImage;
	IBOutlet NSImageView							*serviceImage;
	
	IBOutlet NSTextField							*accountName;
	
	IBOutlet NSTextView								*statusView;
	IBOutlet NSTextView								*profileView;
}

//Methods from AIContentInspectorPane protocol defined in AIContactInfoInspectorController.h
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

//Method from AIListObjectObserver protocol defined in AIContactControllerProtocol.h
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;

@end
