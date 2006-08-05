//
//  SmackXMPPPrivacyPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPPrivacyPlugin.h"
#import "SmackXMPPAccount.h"

@interface SmackXMPPAccount (PrivacyPlugin)

//Add a list object to the privacy list (either AIPrivacyTypePermit or AIPrivacyTypeDeny). Return value indicates success.
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type;
    //Remove a list object from the privacy list (either AIPrivacyTypePermit or AIPrivacyTypeDeny). Return value indicates success
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type;
	//Return an array of AIListContacts on the specified privacy list.  Returns an empty array if no contacts are on the list.
-(NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type;
	//Identical to the above method, except it returns an array of strings, not list objects
-(NSArray *)listObjectIDsOnPrivacyList:(AIPrivacyType)type;
    //Set the privacy options
-(void)setPrivacyOptions:(AIPrivacyOption)option;
	//Get the privacy options
-(AIPrivacyOption)privacyOptions;

@end

@implementation SmackXMPPAccount (PrivacyPlugin)

-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type
{
    return NO; 
}

-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type
{
    return NO;
}

-(NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type
{
    return nil;
}

-(NSArray *)listObjectIDsOnPrivacyList:(AIPrivacyType)type
{
    return nil;
}

-(void)setPrivacyOptions:(AIPrivacyOption)option
{
    
}

-(AIPrivacyOption)privacyOptions
{
    return AIPrivacyOptionUnknown;
}

@end

@implementation SmackXMPPPrivacyPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a {
    if((self = [super init])) {
        account = a;
    }
    return self;
}

- (BOOL)addsProtocolSupport:(Protocol*)proto
{
    return [[NSString stringWithUTF8String:[proto name]] isEqualToString:@"AIAccount_Privacy"];
}

@end
