//
//  ESGaimAIMAccount.h
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "CBGaimOscarAccount.h"


struct oscar_direct_im {
	GaimConnection *gc;
	char name[80];
	int watcher;
	aim_conn_t *conn;
	gboolean connected;
	gboolean gpc_pend;
	gboolean killme;
	gboolean donttryagain;
};

@interface ESGaimAIMAccount : CBGaimOscarAccount <AIAccount_Files> {
	NSTimer			*delayedSignonUpdateTimer;
	NSMutableArray  *arrayOfContactsForDelayedUpdates;
	
	AIHTMLDecoder *encoderCloseFontTagsAttachmentsAsText;
	AIHTMLDecoder *encoderCloseFontTags;
	AIHTMLDecoder *encoderAttachmentsAsText;
}

@end
