//
//  AISMViewController.h
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIListContact, AIAdium, AIFlexibleTableView, AIFlexibleTableColumn;
@protocol AIFlexibleTableViewDelegate;

@interface AISMViewController : NSObject <AIFlexibleTableViewDelegate> {
    AIAdium			*owner;

    AIListContact		*contact;
    AIFlexibleTableView		*messageView;

    AIFlexibleTableColumn	*senderCol;
    AIFlexibleTableColumn	*messageCol;
    AIFlexibleTableColumn	*timeCol;
/*
    NSColor			*backColorIn;
    NSColor			*backColorOut;
    NSColor			*lineColorDivider;
    NSColor			*lineColorDarkDivider;
    NSColor			*outgoingSourceColor;
    NSColor			*outgoingBrightSourceColor;
    NSColor			*incomingSourceColor;
    NSColor			*incomingBrightSourceColor;*/

    NSColor			*outgoingSourceColor;
    NSColor			*outgoingLightSourceColor;
    NSColor			*incomingSourceColor;
    NSColor			*incomingLightSourceColor;

    BOOL			displayPrefix;
    BOOL			displayTimeStamps;
    BOOL			displayGridLines;
    BOOL			displaySenderGradient;
    BOOL			hideDuplicateTimeStamps;
    BOOL			hideDuplicatePrefixes;

    float			gridDarkness;
    float			senderGradientDarkness;
//    float			senderGradientLightness;

    NSFont			*prefixFont;

    NSString			*timeStampFormat;
    NSString			*prefixIncoming;
    NSString			*prefixOutgoing;
}

+ (AISMViewController *)messageViewControllerForContact:(AIListContact *)inContact owner:(id)inOwner;
- (NSView *)messageView;
- (AIListContact *)contact;

@end
