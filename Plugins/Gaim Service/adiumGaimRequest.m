//
//  adiumGaimRequest.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimRequest.h"
#import "ESGaimRequestActionController.h"
#import "ESGaimRequestWindowController.h"

//Jabber registration
#include <libgaim/jabber.h>

static void *adiumGaimRequestInput(const char *title, const char *primary, const char *secondary, const char *defaultValue, gboolean multiline, gboolean masked, gchar *hint,const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData)
{
	/*
	 Multiline should be a paragraph-sized box; otherwise, a single line will suffice.
	 Masked means we want to use an NSSecureTextField sort of thing.
	 We may receive any combination of primary and secondary text (either, both, or neither).
	 */
	
	NSString	*okButtonText = [NSString stringWithUTF8String:okText];
	NSString	*cancelButtonText = [NSString stringWithUTF8String:cancelText];
	
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:okButtonText,@"OK Text",
		cancelButtonText,@"Cancel Text",
		[NSValue valueWithPointer:okCb],@"OK Callback",
		[NSValue valueWithPointer:cancelCb],@"Cancel Callback",
		[NSValue valueWithPointer:userData],@"userData",nil];
	if (title){
		[infoDict setObject:[NSString stringWithUTF8String:title] forKey:@"Title"];	
	}
	if (defaultValue){
		[infoDict setObject:[NSString stringWithUTF8String:defaultValue] forKey:@"Default Value"];
	}
	if (primary){
		[infoDict setObject:[NSString stringWithUTF8String:primary] forKey:@"Primary Text"];
	}
	if (secondary){
		[infoDict setObject:[NSString stringWithUTF8String:secondary] forKey:@"Secondary Text"];
	}
	
	[infoDict setObject:[NSNumber numberWithBool:multiline] forKey:@"Multiline"];
	[infoDict setObject:[NSNumber numberWithBool:masked] forKey:@"Masked"];
	
	[ESGaimRequestWindowController performSelectorOnMainThread:@selector(showInputWindowWithDict:)
													withObject:infoDict
												 waitUntilDone:YES];
	
    return(adium_gaim_get_handle());
}

static void *adiumGaimRequestChoice(const char *title, const char *primary, const char *secondary, unsigned int defaultValue, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData, size_t choiceCount, va_list choices)
{
    GaimDebug (@"adiumGaimRequestChoice");
    return(adium_gaim_get_handle());
}

//Gaim requests the user take an action such as accept or deny a buddy's attempt to add us to her list 
static void *adiumGaimRequestAction(const char *title, const char *primary, const char *secondary, unsigned int default_action,void *userData, size_t actionCount, va_list actions)
{
    int		    i;
	
    NSString	    *titleString = (title ? [NSString stringWithUTF8String:title] : @"");
	NSString		*primaryString = (primary ?  [NSString stringWithUTF8String:primary] : nil);
	
	if (primaryString && ([primaryString rangeOfString: @"wants to send you"].location != NSNotFound)){
		//Redirect a "wants to send you" action request to our file choosing method so we handle it as a normal file transfer
		gaim_xfer_choose_file((GaimXfer *)userData);
		
    }else{
		NSString	    *msg = [NSString stringWithFormat:@"%s%s%s",
			(primary ? primary : ""),
			((primary && secondary) ? "\n\n" : ""),
			(secondary ? secondary : "")];
		
		NSMutableArray  *buttonNamesArray = [NSMutableArray arrayWithCapacity:actionCount];
		GCallback 	    *callBacks = g_new0(GCallback, actionCount);
    	
		//Generate the actions names and callbacks into useable forms
		for (i = 0; i < actionCount; i += 1) {
			//Get the name - XXX evands:need to localize!
			[buttonNamesArray addObject:[NSString stringWithUTF8String:(va_arg(actions, char *))]];
			
			//Get the callback for that name
			callBacks[i] = va_arg(actions, GCallback);
		}
		
		//Make default_action the last one
		if (default_action != -1 && (default_action < actionCount)){
			GCallback tempCallBack = callBacks[actionCount-1];
			callBacks[actionCount-1] = callBacks[default_action];
			callBacks[default_action] = tempCallBack;
			
			[buttonNamesArray exchangeObjectAtIndex:default_action withObjectAtIndex:(actionCount-1)];
		}
		
		NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
			buttonNamesArray,@"Button Names",
			[NSValue valueWithPointer:callBacks],@"callBacks",
			[NSValue valueWithPointer:userData],@"userData",
			titleString,@"Title String",
			msg,@"Message",nil];
		
		[ESGaimRequestActionController performSelectorOnMainThread:@selector(showActionWindowWithDict:)
														withObject:infoDict
													 waitUntilDone:YES];
	}
    return(adium_gaim_get_handle());
}

static void *adiumGaimRequestFields(const char *title, const char *primary, const char *secondary, GaimRequestFields *fields, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData)
{
	NSString *titleString = (title ?  [[NSString stringWithUTF8String:title] lowercaseString] : nil);
	
    if ([titleString rangeOfString: @"new jabber"].location != NSNotFound) {
		/* Jabber registration request. Instead of displaying a request dialogue, we fill in the information automatically. */
		GList					*gl, *fl, *field_list;
		GaimRequestField		*field;
		GaimRequestFieldGroup	*group;
		JabberStream			*js = (JabberStream *)userData;
		GaimAccount				*account = js->gc->account;
		
		//Look through each group, processing each field, searching for username and password fields
		for (gl = gaim_request_fields_get_groups(fields);
			 gl != NULL;
			 gl = gl->next) {
			
			group = gl->data;
			field_list = gaim_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
				GaimRequestFieldType type;
				
				field = (GaimRequestField *)fl->data;
				type = gaim_request_field_get_type(field);
				if (type == GAIM_REQUEST_FIELD_STRING) {
					if (strcasecmp("username", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_username(account));
					}else if (strcasecmp("password", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_password(account));
					}
				}
			}
			
		}
		((GaimRequestFieldsCb)okCb)(userData, fields);
	}
    
	return(adium_gaim_get_handle());
}

static void *adiumGaimRequestFile(const char *title, const char *filename, gboolean savedialog, GCallback ok_cb, GCallback cancel_cb,void *user_data)
{
	GaimXfer *xfer = (GaimXfer *)user_data;
	GaimXferType xferType = gaim_xfer_get_type(xfer);
	if (xfer) {
	    if (xferType == GAIM_XFER_RECEIVE) {
			GaimDebug (@"File request: %s from %s on IP %s",xfer->filename,xfer->who,gaim_xfer_get_remote_ip(xfer));
			
			ESFileTransfer  *fileTransfer;
			NSString		*destinationUID = [NSString stringWithUTF8String:gaim_normalize(xfer->account,xfer->who)];
			
			//Ask the account for an ESFileTransfer* object
			fileTransfer = [accountLookup(xfer->account) newFileTransferObjectWith:destinationUID
																			  size:gaim_xfer_get_size(xfer)
																	remoteFilename:[NSString stringWithUTF8String:(xfer->filename)]];
			
			//Configure the new object for the transfer
			[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
			
			xfer->ui_data = [fileTransfer retain];
			
			//Tell the account that we are ready to request the reception
			[accountLookup(xfer->account) mainPerformSelector:@selector(requestReceiveOfFileTransfer:)
												   withObject:fileTransfer];
			
	    } else if (xferType == GAIM_XFER_SEND) {
			if (xfer->local_filename != NULL && xfer->filename != NULL){
				gaim_xfer_choose_file_ok_cb(xfer, xfer->local_filename);
			}else{
				gaim_xfer_choose_file_cancel_cb(xfer, xfer->local_filename);
				[[SLGaimCocoaAdapter sharedInstance] displayFileSendError];
			}
	    }
		
	}
    
	return(adium_gaim_get_handle());
}

static void adiumGaimRequestClose(GaimRequestType type,void *uiHandle)
{
	
}

static GaimRequestUiOps adiumGaimRequestOps = {
    adiumGaimRequestInput,
    adiumGaimRequestChoice,
    adiumGaimRequestAction,
    adiumGaimRequestFields,
	adiumGaimRequestFile,
    adiumGaimRequestClose
};

GaimRequestUiOps *adium_gaim_request_get_ui_ops()
{
	return &adiumGaimRequestOps;
}
