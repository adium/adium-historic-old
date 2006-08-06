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

#import "BDFireImporter.h"


@implementation BDFireImporter
/*
- (void)importFireAways
{
    [spinner_importProgress setHidden:NO];
    [spinner_importProgress startAnimation:nil];
    [spinner_importProgress display];
    NSAttributedString *newAwayString;
    NSMutableDictionary	*newAwayDict;
    NSString *importingForAccount = [NSString stringWithString:[popUpButton_user titleOfSelectedItem]];
    
    //Create an array of Fire Away Messages
    NSString *firePath = [NSString stringWithString:[@"~/Library/Application Support/Fire/FireConfiguration.plist" stringByExpandingTildeInPath]];
	
    NSDictionary *fireDict = [NSDictionary dictionaryWithContentsOfFile:firePath];
    NSDictionary *fireMessageDict = [fireDict objectForKey:@"awayMessages"];
    
    
    // Create an array of Adium's away messages
    NSString *awayMessagePath = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/Away Messages.plist", importingForAccount] stringByExpandingTildeInPath];
    NSMutableDictionary *adiumDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:awayMessagePath];
    NSArray *tempArray = [NSArray arrayWithArray:[adiumDictionary objectForKey:@"Saved Away Messages"]];
    NSMutableArray *AdiumMessageArray = [[self _loadAwaysFromArray:tempArray] retain];
    // Or, create a blank list if we've never saved one before
    if (AdiumMessageArray == nil)
        AdiumMessageArray = [NSMutableArray array];
    
    
    // Loop through each Fire away message    
    NSEnumerator *AdiumEnumerator = NULL;
    NSDictionary *AdiumMessage; 
    NSDictionary *fireMessage;
    NSString *AdiumMsgTitle, *AdiumMsgContent;
    NSString *fireMsgTitle, *fireMsgContent;
    BOOL messageAlreadyExists;
    
    //Get us an array of all the keys in the dictionary
    NSArray *fireKeyArray = [[[NSArray alloc] initWithArray:[fireMessageDict allKeys]] autorelease];
	
    NSEnumerator *fireEnumerator = [fireKeyArray objectEnumerator];
    while ((fireMsgTitle = [fireEnumerator nextObject]))
    {
        fireMessage = [fireMessageDict objectForKey:fireMsgTitle];
        
        fireMsgContent = [fireMessage objectForKey:@"message"];
        NSLog(fireMsgTitle);
        NSLog(fireMsgContent);
        
        // Loop through each Adium away message and compare it to the current Fire message
        AdiumEnumerator = [AdiumMessageArray objectEnumerator];
        messageAlreadyExists = NO;
        
        while ((AdiumMessage = [AdiumEnumerator nextObject]))
        {
            // If either the title or the content matches, we assume it's already been imported...
            AdiumMsgTitle = [AdiumMessage objectForKey:@"Title"];
            AdiumMsgContent = [AdiumMessage objectForKey:@"Message"];
            
            if ( AdiumMessage && ([AdiumMsgTitle isEqualToString:fireMsgTitle] || [AdiumMsgContent isEqual:fireMsgContent])) {
                messageAlreadyExists = YES;
                break;
            }
        }
        
        
        // If the message isn't already in Adium's list, add it
        if (!messageAlreadyExists) 
        {
            
            // Casting like a drunk fisherman...
            newAwayString = [[[NSAttributedString alloc] initWithString:fireMsgContent 
                                                             attributes:[[self contentController] defaultFormattingAttributes]] autorelease];
            
            // Add the away message to the array... hallelujah!
            
            newAwayDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Away",@"Type",newAwayString,@"Message", fireMsgTitle, @"Title", nil];
            
            
            [AdiumMessageArray addObject:newAwayDict];
        }
        
    }
    NSArray *finalArray = [self _saveArrayFromArray:AdiumMessageArray];
    [adiumDictionary setObject:finalArray forKey:@"Saved Away Messages"];
    NSDictionary *finalDict = [NSDictionary dictionaryWithDictionary:adiumDictionary];
    [spinner_importProgress stopAnimation:nil];
    [spinner_importProgress setHidden:YES];
    
    if ([finalDict writeToFile:[awayMessagePath stringByExpandingTildeInPath] atomically:YES])
    {
        NSBeginAlertSheet(@"Fire messages imported successfully.", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"Your Fire away messages have been imported and are now available in Adium.");
    }
    else
    {
        NSBeginAlertSheet(@"Import failed", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"The import process has encountered an error. Please make sure your permissions are set correctly and try again. If you continue to have problems, please contact an Adium developer.");
    }
}

*/
@end
