//
//  SmackXMPPRegistration.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPRegistration.h"
#import "SmackInterfaceDefinitions.h"
#import <AIUtilities/AIStringUtilities.h>
#import "SmackXMPPFormController.h"
#import "SmackXMPPAccount.h"
#import "AIInterfaceController.h"

#import "SmackCocoaAdapter.h"

@implementation SmackXMPPRegistration

- (id)initWithAccount:(SmackXMPPAccount*)a registerWith:(NSString*)jid
{
    if((self = [super init]))
    {
        account = a;
        otherJID = [jid copy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];

        // request registration form
        SmackRegistration *reg = [SmackCocoaAdapter registration];
        [reg setTo:jid];

        packetID = [[reg getPacketID] retain];
        
        [[account connection] sendPacket:reg];
        
        [self retain];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [otherJID release];
    [packetID release];
    [super dealloc];
}

- (void)handleFormFromPacket:(SmackRegistration*)packet
{
    SmackXForm *form = [SmackCocoaAdapter formFromPacket:(SmackPacket*)packet];
    receivedInitialForm = YES;
    if(!form) {
        wasForm = NO;
        // convert standard form to regular form
        form = [SmackCocoaAdapter formWithType:@"form"];
        JavaMap *attr = [packet getAttributes];
        
        [form setTitle:[NSString stringWithFormat:AILocalizedString(@"Registration for %@","Registration for %@"),otherJID]];
        [form setInstructions:[packet getInstructions]];
        JavaIterator *iter = [[attr keySet] iterator];
        
        while([iter hasNext])
        {
            NSString *key = [iter next];
            SmackXFormField *field;
            if([key isEqualToString:@"registered"])
            {
                field = [SmackCocoaAdapter formFieldWithVariable:@"remove"];
                [field setType:@"boolean"];
                [field setLabel:AILocalizedString(@"Remove registration","Remove registration")];
            } else {
                field = [SmackCocoaAdapter formFieldWithVariable:key];
                [field setType:@"text-single"];
                [field addValue:[attr get:key]];
                if([key isEqualToString:@"username"])
                    [field setLabel:AILocalizedString(@"Account name associated with the user","Account name associated with the user")];
                else if([key isEqualToString:@"nick"])
                    [field setLabel:AILocalizedString(@"Familiar name of the user","Familiar name of the user")];
                else if([key isEqualToString:@"password"])
                {
                    [field setLabel:AILocalizedString(@"Password or secret for the user","Password or secret for the user")];
                    [field setType:@"text-private"];
                } else if([key isEqualToString:@"name"])
                    [field setLabel:AILocalizedString(@"Full name of the user","Full name of the user")];
                else if([key isEqualToString:@"first"])
                    [field setLabel:AILocalizedString(@"First name or given name of the user","First name or given name of the user")];
                else if([key isEqualToString:@"last"])
                    [field setLabel:AILocalizedString(@"Last name, surname, or family name of the user","Last name, surname, or family name of the user")];
                else if([key isEqualToString:@"email"])
                    [field setLabel:AILocalizedString(@"Email address of the user","Email address of the user")];
                else if([key isEqualToString:@"address"])
                    [field setLabel:AILocalizedString(@"Street portion of a physical or mailing address","Street portion of a physical or mailing address")];
                else if([key isEqualToString:@"city"])
                    [field setLabel:AILocalizedString(@"Locality portion of a physical or mailing address","Locality portion of a physical or mailing address")];
                else if([key isEqualToString:@"state"])
                    [field setLabel:AILocalizedString(@"Region portion of a physical or mailing address","Region portion of a physical or mailing address")];
                else if([key isEqualToString:@"zip"])
                    [field setLabel:AILocalizedString(@"Postal code portion of a physical or mailing address","Postal code portion of a physical or mailing address")];
                else if([key isEqualToString:@"phone"])
                    [field setLabel:AILocalizedString(@"Telephone number of the user","Telephone number of the user")];
                else if([key isEqualToString:@"url"])
                    [field setLabel:AILocalizedString(@"URL to web page describing the user","URL to web page describing the user")];
                else if([key isEqualToString:@"date"])
                    [field setLabel:AILocalizedString(@"Some date (e.g., birth date, hire date, sign-up date)","Some date (e.g., birth date, hire date, sign-up date)")];
                else if([key isEqualToString:@"old_password"])
                {
                    [field setLabel:AILocalizedString(@"Old password for the user","Old password for the user")];
                    [field setType:@"text-private"];
                } else
                    [field setLabel:key];
            }
            [form addField:field];
        }
    } else
        wasForm = YES;
    [[SmackXMPPFormController alloc] initWithForm:form target:self selector:@selector(formDidEnd:)];
}

- (void)receivedIQPacket:(NSNotification*)n
{
    SmackIQ *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    // let's filter this one out before moving to the main thread
    // in order to avoid blocking it with things that are thread safe anyways
    if([[packet getPacketID] isEqualToString:packetID])
        [self performSelectorOnMainThread:@selector(receivedIQPacketMainThread:)
                               withObject:packet
                            waitUntilDone:YES];
}

- (void)receivedIQPacketMainThread:(SmackRegistration*)packet
{
    if(receivedInitialForm)
    {
        NSString *type = [[packet getType] toString];
        
        if([type isEqualToString:@"result"])
        {
            [[adium interfaceController] handleMessage:AILocalizedString(@"Registration successful!", "Registration successful!") withDescription:[NSString stringWithFormat:AILocalizedString(@"Registration to %@ was completed successfully.","Registration to %@ was completed successfully."),otherJID] withWindowTitle:AILocalizedString(@"Registration", "Registration")];
            [self release];
            return;
        } else if([type isEqualToString:@"error"] && [SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.Registration"])
        {
            // there is another form required for this stuff
            [self handleFormFromPacket:packet];
        } else {
            // unknown state, probably error with no form
            // let SmackXMPPErrorMessagePlugin handle it
            [self release];
            return;
        }
    } else if([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.Registration"])
    {
        NSString *type = [[packet getType] toString];
        
        if([type isEqualToString:@"error"])
        {
            [self release];
            return;
            // let SmackXMPPErrorMessagePlugin handle it
        }
        
        [self handleFormFromPacket:packet];
    } else { // probably an error message?
        NSLog(@"Received invalid packet for registration request: %@",[packet toXML]);
    }
}

- (void)formDidEnd:(SmackXMPPFormController*)formController
{
    SmackXForm *resultForm = [formController resultForm];
    
    if([[resultForm getType] isEqualToString:@"cancel"])
    {
        // user canceled, the server doesn't have to know about that
        [formController release];
        [self release];
        return;
    }
    
    SmackRegistration *reg = [SmackCocoaAdapter registration];
    
    if(wasForm)
        [reg addExtension:[resultForm getDataFormToSend]];
    else {
        JavaIterator *iter = [resultForm getFields];
        JavaMap *attr = [SmackCocoaAdapter map];
        while([iter hasNext])
        {
            SmackXFormField *field = [iter next];
            if([[field getVariable] isEqualToString:@"remove"])
            {
                NSString *value = [[field getValues] next];
                if([value isEqualToString:@"1"])
                    [attr put:@"remove" :@""]; // just an empty element
            } else {
                NSString *value = [[field getValues] next];
                [attr put:[field getVariable] :value];
            }
        }
        [reg setAttributes:attr];
    }
    
    packetID = [reg getPacketID];
    
    [[account connection] sendPacket:reg];
    
    [formController release];
}

@end
