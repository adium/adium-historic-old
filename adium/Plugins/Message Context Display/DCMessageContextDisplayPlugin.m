//
//  DCMessageContextDisplayPlugin.m
//  Adium
//
//  Created by David Clark on Tuesday, March 23, 2004.
//

#import "DCMessageContextDisplayPlugin.h"

void scandate(const char *sample, unsigned long *outyear, unsigned long *outmonth, unsigned long *outdate);

@interface DCMessageContextDisplayPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation DCMessageContextDisplayPlugin
- (void)installPlugin
{

	isObserving = NO;
	
	//Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTEXT_DISPLAY_DEFAULTS forClass:[self class]] forGroup:PREF_GROUP_CONTEXT_DISPLAY];
    preferences = [[DCMessageContextDisplayPreferences preferencePane] retain];
	
    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
	
	//Always observe chats closing
	[[adium notificationCenter] addObserver:self selector:@selector(saveContextForObject:) name:Chat_WillClose object:nil];

}

- (void)uninstallPlugin
{
    
}

- (void)dealloc
{
    [super dealloc];
}

- (void)preferencesChanged:(NSNotification *)notification
{
	
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTEXT_DISPLAY] == 0){

		NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTEXT_DISPLAY];

		shouldDisplay = [[preferenceDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue];
		linesToDisplay = [[preferenceDict objectForKey:KEY_DISPLAY_LINES] intValue];

		if( shouldDisplay && linesToDisplay > 0 && !isObserving ) {
			
			//Observe new message windows only if we aren't already observing them
			isObserving = YES;
			[[adium notificationCenter] addObserver:self selector:@selector(addContextDisplayToWindow:) name:Chat_DidOpen object:nil];
		} else if ( isObserving && (!shouldDisplay || linesToDisplay <= 0) ) {
			
			//Remove observer
			isObserving = NO;
			[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:nil];
		
		}
		
	}
}

// Save the last few lines of a conversation when it closes
- (void)saveContextForObject:(NSNotification *)notification
{
	int					cnt;
	AIContentObject		*content;
	AIChat				*chat;
	NSMutableDictionary *dict;
	NSDictionary		*contentDict;
	NSEnumerator        *enumerator;
	
	chat = (AIChat *)[notification object];
	dict = [NSMutableDictionary dictionary];
	enumerator = [[chat contentObjectArray] objectEnumerator];
	cnt = 1;
	
	// Only save if we need to save more AND there is still unsaved content available
	while( (cnt <= linesToDisplay) && (content = [enumerator nextObject]) ) {
				
		// Only record actual messages, no context or status
		if( [content isKindOfClass:[AIContentMessage class]] && ![content isKindOfClass:[AIContentContext class]]) {
			contentDict = [self savableContentObject:content];
			[dict setObject:contentDict forKey:[[NSNumber numberWithInt:cnt] stringValue]];
			cnt++;
		}
		
	}
	
	// Did we find anything useful to save? If not, leave it untouched
	if( [dict count] > 0 ) {
		[[chat listObject] setPreference:dict forKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
	}
	
	//NSLog(@"----Dictionary to save: %@",dict);
}

//Returns a dictionary representation of a content object which can be written to disk
//ONLY handles AIContentMessage objects right now
- (NSDictionary *)savableContentObject:(AIContentObject *)content
{
	
	NSMutableDictionary	*contentDict;
	NSString			*sender;
	NSString			*receiver;
	
	contentDict = [NSMutableDictionary dictionary];
	[contentDict setObject:[content type] forKey:@"Type"];
	
	// Outgoing or incoming?
	if( [content isOutgoing] ) {
		sender = [[[content chat] account] uniqueObjectID];
		receiver = [NSString stringWithFormat:@"%@.%@.%@",[[[content chat] listObject] serviceID],[[[content chat] account] UID],[[[content chat] listObject] UID]];
	} else {
		receiver = [[[content chat] account] uniqueObjectID];
		sender = [NSString stringWithFormat:@"%@.%@.%@",[[[content chat] listObject] serviceID],[[[content chat] account] UID],[[[content chat] listObject] UID]];
	}

	[contentDict setObject:sender forKey:@"From"];
	[contentDict setObject:receiver forKey:@"To"];
	[contentDict setObject:[NSNumber numberWithBool:[content isOutgoing]] forKey:@"Outgoing"];
	
	// ONLY log AIContentMessages right now... no status messages
	[contentDict setObject:[NSNumber numberWithBool:[(AIContentMessage *)content autoreply]] forKey:@"Autoreply"];
	[contentDict setObject:[[(AIContentMessage *)content date] description] forKey:@"Date"];
	[contentDict setObject:[[[(AIContentMessage *)content message] safeString]dataRepresentation] forKey:@"Message"];
	
	return(contentDict);
	
}


- (void)addContextDisplayToWindow:(NSNotification *)notification
{
	
	int					cnt;
	AIChat				*chat;
	NSString			*type;
	NSAttributedString  *message;
	AIContentContext	*responseContent;
	id					source;
	id					dest;
		
	chat = (AIChat *)[notification object];

	NSDictionary	*chatDict = [[chat listObject] preferenceForKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
	NSDictionary	*messageDict;
	
	if( chatDict && shouldDisplay && linesToDisplay > 0 ) {
		
		//Max number of lines to display
		cnt = ([chatDict count] >= linesToDisplay ? linesToDisplay : [chatDict count]);
		
		//Add messages until: we add our max (linesToDisplay) OR we run out of saved messages
		while( (messageDict = [chatDict objectForKey:[[NSNumber numberWithInt:cnt] stringValue]]) && cnt > 0 ) {
			
			//NSLog(@"#### Adding number %d: %@",[chatDict count]-cnt,[[NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]] string]);
			
			cnt--;
			
			type = [messageDict objectForKey:@"Type"];
			
			//Currently, we only add Message content objects
			if( [type compare:CONTENT_MESSAGE_TYPE] == 0 ) {
				message = [NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]];
				
				NSString *from = [messageDict objectForKey:@"From"];
				NSString *to = [messageDict objectForKey:@"To"];
				
				// Was the message outgoing?
				if( [[messageDict objectForKey:@"Outgoing"] boolValue] ) {
					dest = [chat listObject];
					source = [[adium accountController] accountWithObjectID:from];
				} else {
					source = [chat listObject];
					dest = [[adium accountController] accountWithObjectID:to];
				}
				
				// Make the message response if all is well
				responseContent = [AIContentContext messageInChat:chat
													   withSource:source
													  destination:dest
															 date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
														  message:message
														autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];
				
				[[adium contentController] displayContentObject:responseContent];
			}
			
		}
		
	}
	
}

@end
