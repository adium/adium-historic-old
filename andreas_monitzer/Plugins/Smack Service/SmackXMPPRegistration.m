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
#import "AIAdium.h"
#import "SmackCocoaAdapter.h"
#import "ESTextAndButtonsWindowController.h"

@interface SmackXMPPAccount (registrationDelegate)

- (void)registration:(SmackXMPPRegistration*)reg didEndWithSuccess:(BOOL)success;
- (WebView*)webView;

@end

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
    [resultForm release];
    [super dealloc];
}

- (void)handleFormFromPacket:(SmackRegistration*)packet
{
    JavaMap *attr = [packet getAttributes];
    SmackXForm *form = [SmackCocoaAdapter formFromPacket:(SmackPacket*)packet];
    
    receivedInitialForm = YES;
    if(!form) {
        wasForm = NO;

        if([attr size] == 0) // no attributes supplied? might be jabber:x:oob (redirect to a URL)
        {
            SmackOutOfBandExtension *oob = [packet getExtension:@"x" :@"jabber:x:oob"];
            if(oob && [[oob getUrl] length] > 0)
                [[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"Registration For %@","Registration For %@"),[packet getFrom]]
                                             withDescription:[packet getInstructions]
                                             withWindowTitle:AILocalizedString(@"Registration","Registration")
                                               defaultButton:AILocalizedString(@"Open URL","Open URL")
                                             alternateButton:AILocalizedString(@"Cancel","Cancel")
                                                 otherButton:nil
                                                      target:[self class] // self doesn't exist any more when this dialog is finished
                                                    selector:@selector(openURLRequest:userInfo:)
                                                    userInfo:oob];
            else
                [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Empty Form Provided by %@","Empty Form Provided by %@"),[packet getFrom]] withDescription:AILocalizedString(@"The form supplied did not contain any fields. Cannot continue.","The form supplied did not contain any fields. Cannot continue.")];
            
            
            [self release]; // no longer our job, let's resign
            return;
        }

        // convert standard form to regular form
        form = [SmackCocoaAdapter formWithType:@"form"];

        [form setTitle:[NSString stringWithFormat:AILocalizedString(@"Registration for %@","Registration for %@"),otherJID]];
        [form setInstructions:[packet getInstructions]];
        
        static NSArray *fielddefinitions = nil;

        if(!fielddefinitions)
            fielddefinitions = [[NSArray alloc] initWithObjects:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"username", @"field",
                    AILocalizedString(@"Account name","Account name associated with the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"nick", @"field",
                    AILocalizedString(@"Familiar name","Familiar name of the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"password", @"field",
                    AILocalizedString(@"Password or secret","Password or secret for the user"), @"label",
                    @"text-private", @"type",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"name", @"field",
                    AILocalizedString(@"Full name","Full name of the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"first", @"field",
                    AILocalizedString(@"First name or given name","First name or given name of the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"last", @"field",
                    AILocalizedString(@"Last name, surname, or family name","Last name, surname, or family name of the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"email", @"field",
                    AILocalizedString(@"Email address","Email address of the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"address", @"field",
                    AILocalizedString(@"Street portion of a physical or mailing address","Street portion of a physical or mailing address"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"city", @"field",
                    AILocalizedString(@"Locality portion of a physical or mailing address","Locality portion of a physical or mailing address"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"state", @"field",
                    AILocalizedString(@"Region portion of a physical or mailing address","Region portion of a physical or mailing address"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"zip", @"field",
                    AILocalizedString(@"Postal code portion of a physical or mailing address","Postal code portion of a physical or mailing address"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"phone", @"field",
                    AILocalizedString(@"Telephone number","Telephone number of the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"url", @"field",
                    AILocalizedString(@"URL to web page","URL to web page describing the user"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"date", @"field",
                    AILocalizedString(@"Some date (e.g., birth date, hire date, sign-up date)","Some date (e.g., birth date, hire date, sign-up date)"), @"label",
                    nil],
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"old_password", @"field",
                    AILocalizedString(@"Old password","Old password for the user"), @"label",
                    @"text-private", @"type",
                    nil],
                nil];
        
        NSEnumerator *e = [fielddefinitions objectEnumerator];
        NSDictionary *item;
        
        while((item = [e nextObject]))
        {
            NSString *fieldname = [item objectForKey:@"field"];
            if([attr containsKey:fieldname])
            {
                NSString *value = [attr get:fieldname];
                SmackXFormField *field = [SmackCocoaAdapter formFieldWithVariable:fieldname];
                if(![item objectForKey:@"type"])
                    [field setType:@"text-single"];
                else
                    [field setType:[item objectForKey:@"type"]];
                [field addValue:value];
                // for some reason unthinkable to men, -setLabel: isn't bridged (even though all other methods are
                // however, I can use my super-advanced method for calling overloaded Java methods, which works fine in this case
                [SmackCocoaAdapter invokeObject:field methodWithParamTypeAndParam:@"setLabel",@"java.lang.String",[item objectForKey:@"label"],nil];

                [form addField:field];
            }
        }
        
    } else
        wasForm = YES;
    [[SmackXMPPFormController alloc] initWithForm:form target:self selector:@selector(formDidEnd:) webView:[account respondsToSelector:@selector(webView)]?[account webView]:nil registered:[attr containsKey:@"registered"]];
}

+ (void)openURLRequest:(NSNumber*)result userInfo:(SmackOutOfBandExtension*)oob
{
    if([result intValue] == AITextAndButtonsDefaultReturn)
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[oob getUrl]]];
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
            if(didUnregister)
                [[adium interfaceController] handleMessage:AILocalizedString(@"Unregistration Successful!", "Unregistration Successful!") withDescription:[NSString stringWithFormat:AILocalizedString(@"Unregistration to %@ was completed successfully.","Unregistration to %@ was completed successfully."),otherJID] withWindowTitle:AILocalizedString(@"Registration", "Registration")];
            else
                [[adium interfaceController] handleMessage:AILocalizedString(@"Registration Successful!", "Registration Successful!") withDescription:[NSString stringWithFormat:AILocalizedString(@"Registration to %@ was completed successfully.","Registration to %@ was completed successfully."),otherJID] withWindowTitle:AILocalizedString(@"Registration", "Registration")];

            if([account respondsToSelector:@selector(registration:didEndWithSuccess:)])
                [account registration:self didEndWithSuccess:YES];
            [self release];
            return;
        } else if([type isEqualToString:@"error"] && [[[SmackCocoaAdapter formFromPacket:(SmackPacket*)packet] getType] isEqualToString:@"form"])
        {
            // there is another form required for this stuff
            [self handleFormFromPacket:packet];
        } else {
            // unknown state, probably error with no form
            // let SmackXMPPErrorMessagePlugin handle it
            if([account respondsToSelector:@selector(registration:didEndWithSuccess:)])
                [account registration:self didEndWithSuccess:NO];
            [self release];
            return;
        }
    } else if([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.Registration"])
    {
        NSString *type = [[packet getType] toString];
        
        if([type isEqualToString:@"error"])
        {
            if([account respondsToSelector:@selector(registration:didEndWithSuccess:)])
                [account registration:self didEndWithSuccess:NO];

            [self release];
            return;
            // let SmackXMPPErrorMessagePlugin handle it
        }
        
        [self handleFormFromPacket:packet];
    } else { // probably an error message?
        NSLog(@"Received invalid packet for registration request: %@",[packet toXML]);
    }
}

- (SmackXForm*)resultForm
{
    return resultForm;
}

- (void)formDidEnd:(SmackXMPPFormController*)formController
{
    resultForm = [[formController resultForm] retain];
    
    if([[resultForm getType] isEqualToString:@"cancel"])
    {
        // user canceled, the server doesn't have to know about that
        [formController release];
        if([account respondsToSelector:@selector(registration:didEndWithSuccess:)])
            [account registration:self didEndWithSuccess:NO];
        [self release];
        return;
    }
    
    SmackRegistration *reg = [SmackCocoaAdapter registration];

    didUnregister = NO;

    SmackXFormField *removefield = [resultForm getField:@"http://adiumx.com/smack/remove"];
    if(removefield)
    {
        JavaIterator *fieldvalueiter = [removefield getValues];
        if([fieldvalueiter hasNext])
        {
            NSString *value = [fieldvalueiter next];
            if([value isEqualToString:@"1"])
            {
                // remove has to be the only element we send
                JavaMap *attr = [SmackCocoaAdapter map];
                [attr put:@"remove" :@""]; // just an empty element
                didUnregister = YES;
                
                [reg setAttributes:attr];
            }
        }
    }
    if(!didUnregister) {
        if(wasForm)
            [reg addExtension:[resultForm getDataFormToSend]];
        else {
            JavaIterator *iter = [resultForm getFields];
            JavaMap *attr = [SmackCocoaAdapter map];
            while([iter hasNext])
            {
                SmackXFormField *field = [iter next];
                
                NSString *value = [[field getValues] next];
                [attr put:[field getVariable] :value];
            }
            [reg setAttributes:attr];
        }
    }
    [reg setTo:otherJID];
    [reg setType:@"set"];
    [packetID release];
    packetID = [[reg getPacketID] retain];
    
    [[account connection] sendPacket:reg];
    
    [formController release];
}

@end
