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
#import "ESGaimRequestActionController.h"
#import "ESGaimRequestWindowController.h"
#import "ESGaimMeanwhileContactAdditionController.h"
#import <AIUtilities/CBObjectAdditions.h>
#import <Adium/ESFileTransfer.h>

//Jabber registration
#include <Libgaim/jabber.h>

/* resolved id for Meanwhile */
struct resolved_id {
	char *id;
	char *name;
};

static void *adiumGaimRequestInput(const char *title, const char *primary, const char *secondary, const char *defaultValue, gboolean multiline, gboolean masked, gchar *hint,const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData)
{
	/*
	 Multiline should be a paragraph-sized box; otherwise, a single line will suffice.
	 Masked means we want to use an NSSecureTextField sort of thing.
	 We may receive any combination of primary and secondary text (either, both, or neither).
	 */
	
	NSString			*okButtonText = [NSString stringWithUTF8String:okText];
	NSString			*cancelButtonText = [NSString stringWithUTF8String:cancelText];
	NSString			*primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	NSMutableDictionary *infoDict;
	
	//Ignore gaim trying to get an account's password; we'll feed it the password and reconnect if it gets here, somehow.
	if([primaryString rangeOfString:@"Enter password for "].location != NSNotFound){
		return;
	}
	
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
	
	[ESGaimRequestWindowController performSelectorOnMainThread:@selector(showInputWindowWithDict:)
													withObject:infoDict
												 waitUntilDone:YES];
	
    return(adium_gaim_get_handle());
}

static void *adiumGaimRequestChoice(const char *title, const char *primary, const char *secondary, unsigned int defaultValue, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData, size_t choiceCount, va_list choices)
{
	GaimDebug (@"adiumGaimRequestChoice: %s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));

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

    if (titleString && 
		[titleString rangeOfString:@"new jabber"].location != NSNotFound) {
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
						const char	*username;
						NSString	*usernameString;
						NSRange		serverAndResourceBeginningRange;
						
						//Process the username to remove the server and the resource
						username = gaim_account_get_username(account);
						usernameString = [NSString stringWithUTF8String:username];
						serverAndResourceBeginningRange = [usernameString rangeOfString:@"@"];
						if(serverAndResourceBeginningRange.location != NSNotFound){
							usernameString = [usernameString substringToIndex:serverAndResourceBeginningRange.location];
						}
						
						gaim_request_field_string_set_value(field, [usernameString UTF8String]);
					}else if (strcasecmp("password", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_password(account));
					}
				}
			}
			
		}
		((GaimRequestFieldsCb)okCb)(userData, fields);
		
	}else if(titleString &&
			 [titleString rangeOfString:@"select user to add"].location != NSNotFound){
		/* Meanwhile ambiguous ID... hack implementation until a full request fields UI exists */
		GList					*gl, *fl, *field_list;
		GaimRequestField		*field;
		GaimRequestFieldGroup	*group;
		NSMutableArray			*possibleUsers = [NSMutableArray array];
		NSDictionary			*infoDict;
		NSValue					*fieldsValue = [NSValue valueWithPointer:fields];
		NSValue					*listFieldValue = nil;
		
		//Look through each group, processing each field, searching for the user field
		for (gl = gaim_request_fields_get_groups(fields);
			 gl != NULL;
			 gl = gl->next) {
			
			group = gl->data;
			field_list = gaim_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
				GaimRequestFieldType type;
				
				field = (GaimRequestField *)fl->data;
				type = gaim_request_field_get_type(field);
				if (type == GAIM_REQUEST_FIELD_LIST) {
					if (strcasecmp("user", gaim_request_field_get_id(field)) == 0){
						//Found the user field, which is a list of names and IDs
						const GList *l;
						
						//Get all items
						for (l = gaim_request_field_list_get_items(field); l != NULL; l = l->next){
							const char			*name = (const char *)l->data;
							struct resolved_id	*res = gaim_request_field_list_get_data(field, name);
							[possibleUsers addObject:[NSValue valueWithPointer:res]];
						}
						
						//Store the reference to this field so we don't have to find it again
						listFieldValue = [NSValue valueWithPointer:field];
					}
				}
			}
		}
		
		/* secondary is 
		 * ("The identifier '%s' may possibly refer to any of the following"
		 * " users. Please select the correct user from the list below to"
		 * " add them to your buddy list.");
		 */
		NSString	*secondaryString = [NSString stringWithUTF8String:secondary];
		NSString	*originalName;
		NSRange		preRange,postRange;
		preRange = [secondaryString rangeOfString:@"The identifier '"];
		postRange = [secondaryString rangeOfString:@"' may possibly refer to any of the following"];
		originalName = [secondaryString substringWithRange:NSMakeRange(preRange.location+preRange.length,
																	   postRange.location - (preRange.location+preRange.length))];		
		
		infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSValue valueWithPointer:okCb],@"OK Callback",
			[NSValue valueWithPointer:cancelCb],@"Cancel Callback",
			[NSValue valueWithPointer:userData],@"userData",
			listFieldValue,@"listFieldValue",
			fieldsValue,@"fieldsValue",
			possibleUsers, @"Possible Users",
			originalName, @"Original Name",
			nil];

		[ESGaimMeanwhileContactAdditionController performSelectorOnMainThread:@selector(showContactAdditionListWithDict:)
																   withObject:infoDict
																waitUntilDone:YES];
	}else{		
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
					if (strcasecmp("username", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_username(account));
					}else if (strcasecmp("password", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_password(account));
					}
				}
				 */
			}
			
		}
//		((GaimRequestFieldsCb)okCb)(userData, fields);
	}
    
	return(adium_gaim_get_handle());
}

static void *adiumGaimRequestFile(const char *title, const char *filename, gboolean savedialog, GCallback ok_cb, GCallback cancel_cb,void *user_data)
{
	NSString	*titleString = (title ? [NSString stringWithUTF8String:title] : nil);
	if(titleString &&
	   ([titleString rangeOfString:@"Sametime"].location != NSNotFound)){
		   if([titleString rangeOfString:@"Export"].location != NSNotFound){
			   NSSavePanel *savePanel = [NSSavePanel savePanel];
			   
			   if([savePanel runModalForDirectory:nil file:nil] == NSOKButton){
				   ((GaimRequestFileCb)ok_cb)(user_data, [[savePanel filename] UTF8String]);
			   }
		   }else if([titleString rangeOfString:@"Import"].location != NSNotFound){
			   NSOpenPanel *openPanel = [NSOpenPanel openPanel];
			   
			   if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
				   ((GaimRequestFileCb)ok_cb)(user_data, [[openPanel filename] UTF8String]);
			   }
		   }		   
		   
	   }else{
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
