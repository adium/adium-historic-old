/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

#import "AIAwayMessagePreferences.h"
#import "AIAwayMessagesPlugin.h"

#define AWAY_MESSAGES_PREF_TITLE    AILocalizedString(@"Away Messages", nil) // Title of the preference view
#define AWAY_NEW_MESSAGE_STRING     AILocalizedString(@"<New Away Message>", nil)
#define AWAY_LIST_IMAGE             @"AwayIcon"		// Away list image filename

@interface AIAwayMessagePreferences (PRIVATE)
- (void)loadAwayMessages;
- (void)saveAwayMessages;
- (int)numberOfRows;
- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow;
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array;
- (NSArray *)_saveArrayFromArray:(NSArray *)array;
- (void)_displayAwayMessage:(NSMutableDictionary *)awayDict;
- (void)_applyChangesToDisplayedMessage;
- (void)removeObject:(id)targetObject fromArray:(NSMutableArray *)array;
- (int)indexOfObject:(id)targetObject inArray:(NSMutableArray *)array;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
@end

@implementation AIAwayMessagePreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Status_Away);
}
- (NSString *)label{
    return(@"Away Message Prefs");
}
- (NSString *)nibName{
    return(@"AwayMessagePrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    awayMessageArray = nil;
    displayedMessage = nil;
    dragItem = nil;
    
    //Configure our view
    [outlineView_aways setDrawsAlternatingRows:YES];
    [outlineView_aways registerForDraggedTypes:[NSArray arrayWithObject:@"AIAwayMessage"]];
    [scrollView_awayList setAutoHideScrollBar:YES];
    [scrollView_awayList setAutoScrollToBottom:NO];

    [scrollView_awayText setAutoHideScrollBar:YES];
    [scrollView_awayText setAutoScrollToBottom:NO];
	[scrollView_awayText setAlwaysDrawFocusRingIfFocused:YES];

	[scrollView_autoresponseText setAutoHideScrollBar:YES];
    [scrollView_autoresponseText setAutoScrollToBottom:NO];
	[scrollView_autoresponseText setAlwaysDrawFocusRingIfFocused:YES];

    //Load our aways
    [self loadAwayMessages];
}

//Preference view is closing
- (void)viewWillClose
{
    [awayMessageArray release]; awayMessageArray = nil;
}


//Loading & Saving -----------------------------------------------------------------------------------------------------
#pragma mark Loading & Saving
//Load the away messages
- (void)loadAwayMessages
{
    NSArray	*tempArray;
    
    //Release any existing away array
    [awayMessageArray release];
    
    //Load the saved away messages
    tempArray = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    if(tempArray){
        //Load the aways
        awayMessageArray = [[self _loadAwaysFromArray:tempArray] retain];
    }else{
        //If no aways exist, create an empty array
        awayMessageArray = [[NSMutableArray alloc] init];
    }
    
    //Refresh our view
    [outlineView_aways reloadData];
    [self outlineViewSelectionDidChange:nil];
}

//Save the away messages
- (void)saveAwayMessages
{
    NSArray	*tempArray;
    
    //Rebuild the away message array, converting all attributed string to NSData's that are suitable for saving
    tempArray = [self _saveArrayFromArray:awayMessageArray];
    
    //Save the away message array
    [[adium preferenceController] setPreference:tempArray forKey:KEY_SAVED_AWAYS group:PREF_GROUP_AWAY_MESSAGES];
}

//Recursively load the away messages, rebuilding the structure with mutable objects
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*mutableArray = [NSMutableArray array];
    
    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _loadAwaysFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];
            
        }else if([type isEqualToString:@"Away"]){
            NSMutableDictionary     *newDict = [NSMutableDictionary dictionary];
            NSString                *title = [dict objectForKey:@"Title"];
            NSData                  *autoresponse = [dict objectForKey:@"Autoresponse"];
            
            [newDict setObject:@"Away" forKey:@"Type"];
            [newDict setObject:[NSAttributedString stringWithData:[dict objectForKey:@"Message"]] forKey:@"Message"];
            
            if(title && [title length]){
                [newDict setObject:title forKey:@"Title"];
            }
            
            if(autoresponse){
                [newDict setObject:[NSAttributedString stringWithData:autoresponse] forKey:@"Autoresponse"];
            }
            
            [mutableArray addObject:newDict];
        }
    }
    return(mutableArray);
}

//Recursively build a savable away message array (replacing NSAttributedString with NSData)
- (NSArray *)_saveArrayFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*saveArray = [NSMutableArray array];

    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){
            [saveArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _saveArrayFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];
            
        }else if([type isEqualToString:@"Away"]){
            NSMutableDictionary     *newDict = [NSMutableDictionary dictionary];
            NSString                *title = [dict objectForKey:@"Title"];
            NSData                  *autoresponse = [[dict objectForKey:@"Autoresponse"] dataRepresentation];
            
            [newDict setObject:@"Away" forKey:@"Type"];
            [newDict setObject:[[dict objectForKey:@"Message"] dataRepresentation] forKey:@"Message"];
            
            if(title && [title length]){
                [newDict setObject:title forKey:@"Title"];
            }
            
            if(autoresponse){
                [newDict setObject:autoresponse forKey:@"Autoresponse"];
            }
            
            [saveArray addObject:newDict];
        }
    }

    return(saveArray);
}


// Import away messages from iChat
- (IBAction)importiChatAways:(id)sender
{
    NSAttributedString *newAwayString;
    NSMutableDictionary	*newAwayDict;
        
    // Create array of iChat away messages
    NSString *iChatPath = [NSString stringWithString:[@"~/Library/Preferences/com.apple.iChat.plist" stringByExpandingTildeInPath]];
    NSDictionary *iChatDict = [NSDictionary dictionaryWithContentsOfFile:iChatPath];
    NSArray *iChatMessageArray = [iChatDict objectForKey:@"CustomAwayMessages"];
    
    // Create an array of Adium's away messages
    NSMutableArray *AdiumMessageArray = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    
    // Or, create a blank list if we've never saved one before
    if (AdiumMessageArray == nil)
        AdiumMessageArray = [NSMutableArray array];
    
    // Loop through each iChat away message
    NSEnumerator *iChatEnumerator = [iChatMessageArray objectEnumerator];
    NSEnumerator *AdiumEnumerator = NULL;
    NSDictionary *AdiumMessage; 
    NSString *iChatMsgTitle, *iChatMsgContent;
    NSString *AdiumMsgTitle, *AdiumMsgContent;
    BOOL messageAlreadyExists;
    
    while(iChatMsgContent = [iChatEnumerator nextObject])
    {
        
        // Create a title for the message by truncating it
        iChatMsgTitle = [iChatMsgContent stringWithEllipsisByTruncatingToLength:25];
        
        // Loop through each Adium away message and compare it to the current iChat message
        AdiumEnumerator = [AdiumMessageArray objectEnumerator];
        messageAlreadyExists = NO;
        
        while(AdiumMessage = [AdiumEnumerator nextObject])
        {
            AdiumMsgTitle = [AdiumMessage objectForKey:@"Title"];
            AdiumMsgContent = [AdiumMessage objectForKey:@"Message"];
            
            
            
            // If either the title or the content matches, we assume it's already been imported...
            if ( AdiumMessage && ([AdiumMsgTitle isEqualToString:iChatMsgTitle] || [AdiumMsgContent isEqual:iChatMsgContent])) {
                messageAlreadyExists = YES;
                break;
            }
        }
        
        // If the message isn't already in Adium's list, add it
        if (!messageAlreadyExists) {
            
            // Casting like a drunk fisherman...
            newAwayString = [[[NSAttributedString alloc] initWithString:iChatMsgContent 
                                                             attributes:[[adium contentController] defaultFormattingAttributes]] autorelease];
            
            // Add the away message to the array... hallelujah!
            
            newAwayDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Away",@"Type",newAwayString,@"Message", iChatMsgTitle, @"Title", nil];
            [awayMessageArray addObject:newAwayDict];
        }
        
        
        
    }
    
    [outlineView_aways reloadData];
    
}


//Display & Editing ----------------------------------------------------------------------------------------------------
#pragma mark Display & Editing
//User finished editing an away message
- (void)textDidEndEditing:(NSNotification *)notification
{
    //Apply and save any changes made
    [self _applyChangesToDisplayedMessage];
    [self saveAwayMessages];
}

//User is editing an away message
- (void)textDidChange:(NSNotification *)notification
{
    //Redisplay
    [outlineView_aways setNeedsDisplay:YES];
    
    if ([notification object] == textView_message) {
        if (!([displayedMessage objectForKey:@"Autoresponse"])) {
            [[textView_autoresponse textStorage] setAttributedString:[textView_message textStorage]];
        }
    }
}

//Display the specified away message in the text view (pass nil to clear the text view & disable it)
- (void)_displayAwayMessage:(NSMutableDictionary *)awayDict
{
    if(awayDict){
        NSString	*type;
        
        //Get the selected item
        type = [awayDict objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){
            //Empty our text view, and disable it
            [textView_message setString:@""];
            [textView_message setEditable:NO];
            [textView_message setSelectable:NO];
            [textView_autoresponse setString:@""];
            [textView_autoresponse setEditable:NO];
            [textView_autoresponse setSelectable:NO];
        }else if([type isEqualToString:@"Away"]){
            //Show the away message in our text view, and enable it for editing
            NSAttributedString * autoresponse = [awayDict objectForKey:@"Autoresponse"];
            BOOL hasAutoresponse = ([[autoresponse string] length] > 0);
            
            [[textView_message textStorage] setAttributedString:[awayDict objectForKey:@"Message"]];
            [[textView_autoresponse textStorage] setAttributedString:hasAutoresponse ? autoresponse : [awayDict objectForKey:@"Message"]];
            
            [textView_message setEditable:YES];
            [textView_message setSelectable:YES];	    
            [textView_autoresponse setEditable:YES];
            [textView_autoresponse setSelectable:YES];
        }
    }else{
        [textView_message setString:@""];
        [textView_message setEditable:NO];
        [textView_message setSelectable:NO];
        [textView_autoresponse setString:@""];
        [textView_autoresponse setEditable:NO];
        [textView_autoresponse setSelectable:NO];
    }
    
    displayedMessage = awayDict;
}

//Apply text view changes to the displayed away message
- (void)_applyChangesToDisplayedMessage
{
    NSString	*type;
    
    if(displayedMessage){
        //Get the selected item
        type = [displayedMessage objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){
            //Nothing can be changed about groups
            
        }else if([type isEqualToString:@"Away"]){
            //Set the new message
            NSAttributedString * awayMessage = [[[textView_message textStorage] copy] autorelease];
            [displayedMessage setObject:awayMessage forKey:@"Message"];
            
            NSAttributedString * autoresponse = [[[textView_autoresponse textStorage] copy] autorelease];
            
            //same as the away message, or empty
            if ([autoresponse isEqualToAttributedString:awayMessage] || !([[autoresponse string] length])){                         
                [displayedMessage removeObjectForKey:@"Autoresponse"];
            }else{
                [displayedMessage setObject:autoresponse forKey:@"Autoresponse"];
            }
        }
    }
}


//Adding & Removing ----------------------------------------------------------------------------------------------------
#pragma mark Adding & Removing
//Create a new away message
- (IBAction)newAwayMessage:(id)sender
{
    NSAttributedString	*newAwayString;
    NSMutableDictionary	*newAwayDict;
    
    //Give outline view focus to end any editing
    [[outlineView_aways window] makeFirstResponder:outlineView_aways];
    
    //Get the selected group    
    
    //Create the new away entry
    newAwayString = [[[NSAttributedString alloc] initWithString:AWAY_NEW_MESSAGE_STRING 
                                                     attributes:[[adium contentController] defaultFormattingAttributes]] autorelease];
    newAwayDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Away",@"Type",newAwayString,@"Message",nil];
    
    //Add the new away
    [awayMessageArray addObject:newAwayDict];
    
    //Select and scroll to the new away
    [outlineView_aways reloadData];
    [outlineView_aways selectRow:[outlineView_aways rowForItem:newAwayDict] byExtendingSelection:NO];
    [outlineView_aways scrollRowToVisible:[outlineView_aways rowForItem:newAwayDict]];
    [self outlineViewSelectionDidChange:nil];
    
    //Put focus in the away message text view, and select any existing text
    [[textView_message window] makeFirstResponder:textView_message];
    [textView_message setSelectedRange:NSMakeRange(0, [[textView_message textStorage] length])];       
}

//Delete the selected away message
- (IBAction)deleteAwayMessage:(id)sender
{
    NSDictionary	*selectedAway;
    int             selectedRow;
    
    //Delete the selected away
    selectedRow = [outlineView_aways selectedRow];
    selectedAway = [outlineView_aways itemAtRow:selectedRow];
    
    [self removeObject:selectedAway fromArray:awayMessageArray]; //We can't use removeObject, since it will treat similar aways as identical and remove them all!
    
    //reload and save changes 
    [outlineView_aways reloadData];
    
    //If they delete the last away, prevent selection from jumping to the top of the view
    if(selectedRow >= [outlineView_aways numberOfRows]){
        [outlineView_aways selectRow:[outlineView_aways numberOfRows]-1 byExtendingSelection:NO];
    }
    [self outlineViewSelectionDidChange:nil]; //Update the displayed away, since selection has changed
    
    //save
    [self saveAwayMessages];
}

//We often can't use removeObject, since it will treat similar aways as identical and remove them all!  This special version only compares instances, and not their content.
- (void)removeObject:(id)targetObject fromArray:(NSMutableArray *)array
{
    NSEnumerator	*enumerator;
    id			object;
    int			index = 0;
    
    enumerator = [array objectEnumerator];
    while((object = [enumerator nextObject])){
        if(object == targetObject){
            [array removeObjectAtIndex:index];
            break;
        }
        index++;
    }
}

//We often can't use indexOfObject, since it will treat similar aways as identical and always return the first instance.  This special version only compares instances, and not their content.
- (int)indexOfObject:(id)targetObject inArray:(NSMutableArray *)array
{
    NSEnumerator	*enumerator;
    id			object;
    int			index = 0;
    
    enumerator = [array objectEnumerator];
    while((object = [enumerator nextObject])){
        if(object == targetObject){
            return(index);
        }
        index++;
    }
    
    return(-1);
}


//Away Message Table ---------------------------------------------------------------------------------------------------
#pragma mark Away Message Table
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){ //Root
        return([awayMessageArray count]);
    }else{
        NSString *type = [item objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){ //Group
            return([(NSArray *)[item objectForKey:@"Contents"] count]);
        }else{
            return(0);
        }
        
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([awayMessageArray objectAtIndex:index]);
    }else{
        NSString *type = [item objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){ //Group
            return([[item objectForKey:@"Contents"] objectAtIndex:index]);
        }else{
            return(nil);
        }
        
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    NSString *type = [item objectForKey:@"Type"];
    
    if([type isEqualToString:@"Group"]){ //Group
        return(YES);
    }else{
        return(NO);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *type = [item objectForKey:@"Type"];
    
    //If this item is the one we're editing, make it look as if the changes are applying live by pulling the text right from our text view
    if(item == displayedMessage){
        NSString * title = [displayedMessage objectForKey:@"Title"];
        if (!title || [title isEqualToString:[[displayedMessage objectForKey:@"Message"] string]]){
            return([[textView_message textStorage] string]);
        }else{
            return(title);
        }
    }
    
    if([type isEqualToString:@"Group"]){ //Group
        return([item objectForKey:@"Name"]);
    }else if([type isEqualToString:@"Away"]){ //Away message
        NSString * title = [item objectForKey:@"Title"];
        return(title ? title : [[item objectForKey:@"Message"] string]);
    }else{
        return(nil);
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *type = [item objectForKey:@"Type"];
    if([type isEqualToString:@"Away"]){ //Away message
        if(object && [(NSString *)object length] != 0){
            [item setObject:object forKey:@"Title"];
        }else{
            [item removeObjectForKey:@"Title"];
        }
        [self saveAwayMessages];
    }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    int selectedRow = [outlineView_aways selectedRow];
    if((selectedRow != -1) && ([outlineView_aways numberOfRows] != 0)){
        //
        [self _displayAwayMessage:[outlineView_aways itemAtRow:selectedRow]];
        
        //Give focus to the text view
		//**Brandon** - this aggrivates the hell out of me...seriously.
		//if anyone misses it, feel free to uncomment it.

        /*[[textView_message window] makeFirstResponder:textView_message];*/
        
        //Enable delete button
        [button_delete setEnabled:YES];
        
    }else{
        [self _displayAwayMessage:nil];
	
        //Disable delete button
        [button_delete setEnabled:NO];
    }
    
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObject:@"AIAwayMessage"] owner:self];
    
    //Build a list of all the highlighted aways
    dragItem = [items objectAtIndex:0];
    
    //put it on the pasteboard
    [pboard setString:@"Private" forType:@"AIAwayMessage"];
    
    return(YES);
}

- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIAwayMessage"]];
    
    if([avaliableType isEqualToString:@"AIAwayMessage"]){
        NSString *type = [dragItem objectForKey:@"Type"];
        NSString *itemType = [item objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){ //If they are dragging a group
            if(item == nil || [itemType isEqualToString:@"Group"]){ //To root, or onto/into a group
                return(NSDragOperationPrivate);
            }
            
        }else if([type isEqualToString:@"Away"]){ //If they are dragging an away
            if(item == nil || [itemType isEqualToString:@"Group"]){ //To root, or onto/into a group
                return(NSDragOperationPrivate);
            }
        }
    }
    
    return(NSDragOperationNone);
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIAwayMessage"]];
    int			oldIndex = [self indexOfObject:dragItem inArray:awayMessageArray];
    
    if([availableType isEqualToString:@"AIAwayMessage"]){
        NSString *type = [dragItem objectForKey:@"Type"];
        //NSString *itemType = [item objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){ //If they are dragging a group
            /*            
            if(item == nil){ //To root
                
            }else if([itemType isEqualToString:@"Group"]){
                if(index == -1){ //Onto a group
                    
                }else{ //Into a group
                    
                }
            }
            */
        }else if([type isEqualToString:@"Away"]){ //If they are dragging an away
            if(item == nil){ //To root
                [dragItem retain];
				
				//Remove from old location.  We can't use removeObject, since it will treat similar aways as identical
				//and remove them all!
                [self removeObject:dragItem fromArray:awayMessageArray];
                
                if (index == -1){
                    [awayMessageArray addObject:dragItem];
                }else {
                    [awayMessageArray insertObject:dragItem atIndex:(oldIndex > index ? index : index - 1)]; //Add to new location
                }
                
                [dragItem release];
                
            }/*else if([itemType compare:@"Group"] == 0){
                if(index == -1){ //Onto a group
                    
                }else{ //Into a group
                    
                }
            }*/
        }
    }
    
    //Select and scroll to the dragged object
    [outlineView_aways reloadData];
    [outlineView_aways selectRow:[outlineView_aways rowForItem:dragItem] byExtendingSelection:NO];
    [outlineView_aways scrollRowToVisible:[outlineView_aways rowForItem:dragItem]];
    [self outlineViewSelectionDidChange:nil];
    
	//On the next run loop, save the newly-orded away messages array
	[self performSelector:@selector(saveAwayMessages)
			   withObject:nil
			   afterDelay:0.0001];
	
    return(YES);
}

- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)outlineView
{
    [self deleteAwayMessage:nil];    
}

@end
