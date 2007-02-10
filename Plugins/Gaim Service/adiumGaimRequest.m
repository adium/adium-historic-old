/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "adiumGaimRequest.h"
#import "UndeclaredLibgaimFunctions.h"
#import "ESGaimRequestActionController.h"
#import "ESGaimRequestWindowController.h"
#import "ESGaimFileReceiveRequestController.h"
#import "ESGaimMeanwhileContactAdditionController.h"
#import <Adium/NDRunLoopMessenger.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/ESFileTransfer.h>

/*
 * Gaim requires us to return a handle from each of the request functions.  This handle is passed back to use in 
 * adiumGaimRequestClose() if the request window is no longer valid -- for example, a chat invitation window is open,
 * and then the account disconnects.  All window controllers created from adiumGaimRequest.m should return non-autoreleased
 * instances of themselves.  They then release themselves when their window closes.  Rather than calling
 * [[self window] close], they should use gaim_request_close_with_handle(self) to ensure proper bookkeeping gaimside.
 */
 
//Jabber registration
#include <Libgaim/jabber.h>

/* resolved id for Meanwhile */
struct resolved_id {
	char *id;
	char *name;
};

/*!
 * @brief Process button text, removing gtk+ accelerator underscores
 *
 * Textual underscores are indicated by "__"
 */
NSString *processButtonText(NSString *inButtonText)
{
	NSMutableString	*processedText = [inButtonText mutableCopy];
	
#define UNDERSCORE_PLACEHOLDER @"&&&&&"

	//Replace escaped underscores with our placeholder
	[processedText replaceOccurrencesOfString:@"__"
								   withString:UNDERSCORE_PLACEHOLDER
									  options:NSLiteralSearch
										range:NSMakeRange(0, [processedText length])];
	//Remove solitary underscores
	[processedText replaceOccurrencesOfString:@"_"
								   withString:@""
									  options:NSLiteralSearch
										range:NSMakeRange(0, [processedText length])];

	//Replace the placeholder with an underscore
	[processedText replaceOccurrencesOfString:UNDERSCORE_PLACEHOLDER
								   withString:@"_"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [processedText length])];
	
	return [processedText autorelease];
	
}

static void *adiumGaimRequestInput(
								   const char *title, const char *primary,
								   const char *secondary, const char *defaultValue,
								   gboolean multiline, gboolean masked, gchar *hint,
								   const char *okText, GCallback okCb, 
								   const char *cancelText, GCallback cancelCb,
								   void *userData)
{
	/*
	 Multiline should be a paragraph-sized box; otherwise, a single line will suffice.
	 Masked means we want to use an NSSecureTextField sort of thing.
	 We may receive any combination of primary and secondary text (either, both, or neither).
	 */
	id					requestController = nil;
	NSString			*primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	
	//Ignore gaim trying to get an account's password; we'll feed it the password and reconnect if it gets here, somehow.
	if ([primaryString rangeOfString:@"Enter password for "].location != NSNotFound) return [NSNull null];
	
	NSMutableDictionary *infoDict;
	NSString			*okButtonText = processButtonText([NSString stringWithUTF8String:okText]);
	NSString			*cancelButtonText = processButtonText([NSString stringWithUTF8String:cancelText]);
	
	infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:okButtonText,@"OK Text",
		cancelButtonText,@"Cancel Text",
		[NSValue valueWithPointer:okCb],@"OK Callback",
		[NSValue valueWithPointer:cancelCb],@"Cancel Callback",
		[NSValue valueWithPointer:userData],@"userData",nil];
	
	
	if (primaryString) [infoDict setObject:primaryString forKey:@"Primary Text"];
	if (title) [infoDict setObject:[NSString stringWithUTF8String:title] forKey:@"Title"];	
	if (defaultValue) [infoDict setObject:[NSString stringWithUTF8String:defaultValue] forKey:@"Default Value"];
	if (secondary) [infoDict setObject:[NSString stringWithUTF8String:secondary] forKey:@"Secondary Text"];
	
	[infoDict setObject:[NSNumber numberWithBool:multiline] forKey:@"Multiline"];
	[infoDict setObject:[NSNumber numberWithBool:masked] forKey:@"Masked"];
	
	GaimDebug (@"adiumGaimRequestInput: %@",infoDict);
	
	requestController = [ESGaimRequestWindowController showInputWindowWithDict:infoDict];
	
	return (requestController ? requestController : [NSNull null]);
}

static void *adiumGaimRequestChoice(const char *title, const char *primary,
									const char *secondary, unsigned int defaultValue,
									const char *okText, GCallback okCb,
									const char *cancelText, GCallback cancelCb,
									void *userData, va_list choices)
{
	GaimDebug (@"adiumGaimRequestChoice: %s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));
	
	return [NSNull null];
}

//Gaim requests the user take an action such as accept or deny a buddy's attempt to add us to her list 
static void *adiumGaimRequestAction(const char *title, const char *primary,
									const char *secondary, unsigned int default_action,
									void *userData, size_t actionCount, va_list actions)
{
    NSString			*titleString = (title ? [NSString stringWithUTF8String:title] : @"");
	NSString			*primaryString = (primary ?  [NSString stringWithUTF8String:primary] : nil);
	id					requestController = nil;
	int					i;
	
	if (primaryString && ([primaryString rangeOfString:@"wants to send you"].location != NSNotFound)) {
		GCallback ok_cb;
		
		//Get the callback for OK, skipping over the title
		va_arg(actions, char *);
		ok_cb = va_arg(actions, GCallback);
		
		//Redirect a "wants to send you" action request to our file choosing method so we handle it as a normal file transfer
		((GaimRequestActionCb)ok_cb)(userData, default_action);
		
    } else if (primaryString && ([primaryString rangeOfString:@"Create New Room"].location != NSNotFound)) {
		/* Jabber's Create New Room dialog has a default option of accepting default values and another option
		 * of configuration of the room... unfortunately, configuring the room requires a gaim_request_fields
		 * implementation, which we don't have yet, so the dialog is just confusing.  Accept the defaults.
		 */
		// XXX remove when gaim_request_fields is implemented
		for (i = 0; i < actionCount; i += 1) {
			GCallback	tempCallBack;
			char		*buttonName;
			
			//Get the name
			buttonName = va_arg(actions, char *);
			
			//Get the callback for that name
			tempCallBack = va_arg(actions, GCallback);
			
			//Perform the default action
			if (i == default_action) {
				GaimRequestActionCb callBack = (GaimRequestActionCb)tempCallBack;
				callBack(userData, default_action);
				
				break;
			}
		}

	} else {
		NSString	    *msg = [NSString stringWithFormat:@"%s%s%s",
			(primary ? primary : ""),
			((primary && secondary) ? "\n\n" : ""),
			(secondary ? secondary : "")];
		
		NSMutableArray	*buttonNamesArray = [NSMutableArray arrayWithCapacity:actionCount];
		GCallback		*callBacks = g_new0(GCallback, actionCount);
    	
		//Generate the actions names and callbacks into useable forms
		for (i = 0; i < actionCount; i += 1) {
			char *buttonName;
			
			//Get the name
			buttonName = va_arg(actions, char *);
			[buttonNamesArray addObject:processButtonText([NSString stringWithUTF8String:buttonName])];
			
			//Get the callback for that name
			callBacks[i] = va_arg(actions, GCallback);
		}
		
		//Make default_action the last one
		if (default_action != -1 && (default_action < actionCount)) {
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
		
		requestController = [ESGaimRequestActionController showActionWindowWithDict:infoDict];
	}

	return (requestController ? requestController : [NSNull null]);
}

static void *adiumGaimRequestFields(const char *title, const char *primary,
									const char *secondary, GaimRequestFields *fields,
									const char *okText, GCallback okCb,
									const char *cancelText, GCallback cancelCb,
									void *userData)
{
	id					requestController = nil;
	NSString			*titleString = (title ?  [[NSString stringWithUTF8String:title] lowercaseString] : nil);

    if (titleString && 
		[titleString rangeOfString:@"new jabber"].location != NSNotFound) {
		/* Jabber registration request. Instead of displaying a request dialogue, we fill in the information automatically.
		 * And by that, I mean that we accept all the default empty values, since the username and password are preset for us. */
		((GaimRequestFieldsCb)okCb)(userData, fields);
		
	} else {		
		GaimDebug (@"adiumGaimRequestFields: %s\n%s\n%s ",
				   (title ? title : ""),
				   (primary ? primary : ""),
				   (secondary ? secondary : ""));
		
		GList					*gl, *fl, *field_list;
		GaimRequestFieldGroup	*group;

		//Look through each group, processing each field
		for (gl = gaim_request_fields_get_groups(fields);
			 gl != NULL;
			 gl = gl->next) {
			
			group = gl->data;
			field_list = gaim_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
				/*
				typedef enum
				{
					GAIM_REQUEST_FIELD_NONE,
					GAIM_REQUEST_FIELD_STRING,
					GAIM_REQUEST_FIELD_INTEGER,
					GAIM_REQUEST_FIELD_BOOLEAN,
					GAIM_REQUEST_FIELD_CHOICE,
					GAIM_REQUEST_FIELD_LIST,
					GAIM_REQUEST_FIELD_LABEL,
					GAIM_REQUEST_FIELD_ACCOUNT
				} GaimRequestFieldType;
				*/

				/*
				GaimRequestField		*field;
				GaimRequestFieldType	type;
				
				field = (GaimRequestField *)fl->data;
				type = gaim_request_field_get_type(field);
				if (type == GAIM_REQUEST_FIELD_STRING) {
					if (strcasecmp("username", gaim_request_field_get_label(field)) == 0) {
						gaim_request_field_string_set_value(field, gaim_account_get_username(account));
					} else if (strcasecmp("password", gaim_request_field_get_label(field)) == 0) {
						gaim_request_field_string_set_value(field, gaim_account_get_password(account));
					}
				}
				 */
			}
			
		}
//		((GaimRequestFieldsCb)okCb)(userData, fields);
	}
    
	return (requestController ? requestController : [NSNull null]);
}

static void *adiumGaimRequestFile(const char *title, const char *filename,
								  gboolean savedialog, GCallback ok_cb,
								  GCallback cancel_cb,void *user_data)
{
	id					requestController = nil;
	NSString			*titleString = (title ? [NSString stringWithUTF8String:title] : nil);
	
	if (titleString &&
		([titleString rangeOfString:@"Sametime"].location != NSNotFound)) {
		if ([titleString rangeOfString:@"Export"].location != NSNotFound) {
			NSSavePanel *savePanel = [NSSavePanel savePanel];
			
			if ([savePanel runModalForDirectory:nil file:nil] == NSOKButton) {
				((GaimRequestFileCb)ok_cb)(user_data, [[savePanel filename] UTF8String]);
			}
		} else if ([titleString rangeOfString:@"Import"].location != NSNotFound) {
			NSOpenPanel *openPanel = [NSOpenPanel openPanel];
			
			if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
				((GaimRequestFileCb)ok_cb)(user_data, [[openPanel filename] UTF8String]);
			}
		}
	} else {
		GaimXfer *xfer = (GaimXfer *)user_data;
		if (xfer) {
			GaimXferType xferType = gaim_xfer_get_type(xfer);
			
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
				NSDictionary	*infoDict;
				
				infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
					accountLookup(xfer->account), @"CBGaimAccount",
					fileTransfer, @"ESFileTransfer",
					nil];
				requestController = [ESGaimFileReceiveRequestController showFileReceiveWindowWithDict:infoDict];
				AILog(@"GAIM_XFER_RECEIVE: Request controller for %x is %@",xfer,requestController);
			} else if (xferType == GAIM_XFER_SEND) {
				if (xfer->local_filename != NULL && xfer->filename != NULL) {
					AILog(@"GAIM_XFER_SEND: %x (%s)",xfer,xfer->local_filename);
					((GaimRequestFileCb)ok_cb)(user_data, xfer->local_filename);
				} else {
					((GaimRequestFileCb)cancel_cb)(user_data, xfer->local_filename);
					[[SLGaimCocoaAdapter sharedInstance] displayFileSendError];
				}
			}
		}
	}
	
	AILog(@"adiumGaimRequestFile() returning %@",(requestController ? requestController : [NSNull null]));
	return (requestController ? requestController : [NSNull null]);
}

/*!
 * @brief Gaim requests that we close a request window
 *
 * This is not sent after user interaction with the window.  Instead, it is sent when the window is no longer valid;
 * for example, a chat invite window after the relevant account disconnects.  We should immediately close the window.
 *
 * @param type The request type
 * @param uiHandle must be an id; it should either be NSNull or an object which can respond to close, such as NSWindowController.
 */
static void adiumGaimRequestClose(GaimRequestType type, void *uiHandle)
{
	id	ourHandle = (id)uiHandle;
	AILog(@"adiumGaimRequestClose %@ (%i)",uiHandle,[ourHandle respondsToSelector:@selector(gaimRequestClose)]);
	if ([ourHandle respondsToSelector:@selector(gaimRequestClose)]) {
		[ourHandle gaimRequestClose];

	} else if ([ourHandle respondsToSelector:@selector(closeWindow:)]) {
		[ourHandle closeWindow:nil];
	}
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

@implementation ESGaimRequestAdapter

+ (void)requestCloseWithHandle:(id)handle
{
	AILog(@"gaimThreadRequestCloseWithHandle: %@",handle);
	gaim_request_close_with_handle(handle);
}

@end
