//
//  SmackXMPPHeadlineMessagePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPHeadlineMessagePlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"
#import "AIAdium.h"
#import "AIContactController.h"
#import "ESContactAlertsController.h"
#import "AIListContact.h"

#import <AIUtilities/AIStringUtilities.h>

@implementation SmackXMPPHeadlineMessagePlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if ((self = [super init]))
    {
        account = a;
        
        headlines = [[NSMutableArray alloc] init];
        [NSBundle loadNibNamed:@"SmackXMPPHeadlinesViewer" owner:self];
        if (!window)
        {
            NSLog(@"Failed loading SmackXMPPHeadlinesViewer.nib!");
            [self release];
            return nil;
        }
        [window setTitle:[NSString stringWithFormat:AILocalizedString(@"%@ Headlines","headlines window title (%@ is the account name)"),[account UID]]];
        [lastReceived setStringValue:AILocalizedString(@"<none>","headlines window bottom text last headline received none")];
        
        [dateformatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateformatter setDateStyle:NSDateFormatterShortStyle];
        [dateformatter setTimeStyle:NSDateFormatterShortStyle];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedMessagePacket:)
                                                     name:SmackXMPPMessagePacketReceivedNotification
                                                   object:account];
        
        NSMutableParagraphStyle *paragraphstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphstyle setLineBreakMode:NSLineBreakByWordWrapping];
        
        messagestyle = [[NSDictionary alloc] initWithObjectsAndKeys:
            paragraphstyle, NSParagraphStyleAttributeName,
            [NSFont systemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName,
            nil];
        [paragraphstyle release];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [headlines release];
    [messagestyle release];
    [super dealloc];
}

- (void)receivedMessagePacket:(NSNotification*)n
{
    SmackMessage *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if ([[[packet getType] toString] isEqualToString:@"headline"])
        [self performSelectorOnMainThread:@selector(receivedHeadlinePacket:) withObject:packet waitUntilDone:NO];
}

- (void)receivedHeadlinePacket:(SmackMessage *)packet
{
    // date
    SmackXDelayInformation *delayinfo = [packet getExtension:@"x" :@"jabber:x:delay"];
    NSDate *date = nil;
    if (delayinfo)
        date = [SmackCocoaAdapter dateFromJavaDate:[delayinfo getStamp]];
    else
        date = [NSDate date];
    
    // text
    NSAttributedString  *inMessage = nil;
    SmackXXHTMLExtension *spe = [packet getExtension:@"html" :@"http://jabber.org/protocol/xhtml-im"];
    if (spe)
    {
        JavaIterator *iter = [spe getBodies];
        NSString *htmlmsg = nil;
        if (iter && [iter hasNext])
            htmlmsg = [iter next];
        if ([htmlmsg length] > 0)
        {
            inMessage = [[NSMutableAttributedString alloc] initWithHTML:[[NSString stringWithFormat:@"<html>%@</html>",htmlmsg] dataUsingEncoding:NSUnicodeStringEncoding]
                                                                options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnicodeStringEncoding] forKey:NSCharacterEncodingDocumentOption]
                                                     documentAttributes:NULL];
            [(NSMutableAttributedString*)inMessage addAttribute:NSParagraphStyleAttributeName value:[messagestyle objectForKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[inMessage length])];
            // ignore font settings, since that might mess with the formatting of the HTML (bold, italics, etc)
        }
    }
    if (!inMessage)
        inMessage = [[NSAttributedString alloc] initWithString:[packet getBody] attributes:messagestyle];
    
    AIListContact *contact = [[adium contactController] contactWithService:[account service] account:account UID:[packet getFrom]];
    
    [[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED forListObject:contact userInfo:nil previouslyPerformedActionIDs:nil];
    
    [headlinescontroller addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
        contact, @"from",
        inMessage, @"body",
        date, @"date",
        nil]];
    [inMessage release];
    
    [lastReceived setStringValue:[dateformatter stringFromDate:date]];
    
    [window orderFront:nil];
}

- (IBAction)clear:(id)sender
{
    [[self mutableArrayValueForKey:@"headlines"] removeAllObjects];
}

- (NSArray *)accountActionMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Show Headlines Window","Show Headlines Window") action:@selector(showWindow:) keyEquivalent:@""];
    [mitem setTarget:self];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

- (IBAction)showWindow:(id)sender
{
    [window makeKeyAndOrderFront:self];
}

#pragma mark NSTableView delegate methods

- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row
{
    // automatically set the row height to the height of the message
    NSTableColumn *col = [tableView tableColumnWithIdentifier:@"body"];
    NSMutableDictionary *line = [[headlinescontroller arrangedObjects] objectAtIndex:row];
    if (!line)
        return 17.0;
    
    NSValue *sizeval = [line objectForKey:@"size"];
    if (sizeval)
    {
        NSSize size = [sizeval sizeValue];
        if (fabs(size.width - [col width]) < 0.1) // is the width unchanged?
            return size.height; // use cached value
    }

    // otherwise, recalculate and store
    NSAttributedString *body = [line objectForKey:@"body"];
    if (body)
    {
        NSCell *cell = [col dataCellForRow:row];
        [cell setObjectValue:body];
        [cell setWraps:YES];
        float height = [cell cellSizeForBounds:NSMakeRect(0.0,0.0,[col width],FLT_MAX)].height;
        if (height < 17.0) // ensure minimum height
            height = 17.0;
        
        // cache in row dictionary
        [line setObject:[NSValue valueWithSize:NSMakeSize([col width],height)] forKey:@"size"];
        
        return height;
    }
    else
        return 17.0;
}

@end
