//
//  GaimService.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "CBGaimServicePlugin.h"
#import "CBGaimAccount.h"

@interface GaimService : AIObject <AIServiceController> {
    AIServiceType           *handleServiceType;
    CBGaimServicePlugin     *service;
    
    IBOutlet 	NSView      *view_preferences;
}

- (id)initWithService:(CBGaimServicePlugin *)inService;
- (void)addAccount:(CBGaimAccount *)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct;
- (void)removeAccount:(GaimAccount *)gaimAcct;
- (BOOL)configureGaimProxySettings;
- (NSString *)gaimDescriptionSuffix;

@end
