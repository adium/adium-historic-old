//
//  ESGaimJabberAccount.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimAccount.h"

#define KEY_JABBER_HOST				@"Jabber:Host"
#define KEY_JABBER_PORT				@"Jabber:Port"

#define KEY_JABBER_CONNECT_SERVER   @"Jabber:Connect Server"
#define KEY_JABBER_RESOURCE			@"Jabber:Resource"
#define KEY_JABBER_USE_TLS			@"Jabber:Use TLS"
#define KEY_JABBER_FORCE_OLD_SSL	@"Jabber:Force Old SSL"
#define KEY_JABBER_ALLOW_PLAINTEXT  @"Jabber:Allow Plaintext Authentication"

@interface ESGaimJabberAccount : CBGaimAccount <AIAccount_Files> {

}

@end