/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <AIUtilities/AIUtilities.h>
#import "AIEditorImportCollection.h"

@interface AIEditorImportCollection (PRIVATE)
- (id)initWithPath:(NSString *)inPath owner:(id)inOwner;
- (void)importFromPath:(NSString *)inPath;
- (NSString *)makeStringPretty:(NSString *)string;
- (NSMutableArray *)importContactsFromPath:(NSString *)inPath;
@end

@implementation AIEditorImportCollection

//Return an empty collection 
//Retun collection from a path, set the name
 + (AIEditorImportCollection *)editorCollectionWithPath:(NSString *)inPath owner:(id)inOwner
{
    return([[[self alloc] initWithPath:inPath owner:inOwner] autorelease]);
}

//path initializer
- (id)initWithPath:(NSString *)inPath owner:(id)inOwner
{
    [super initWithOwner:inOwner];

    path = [inPath retain];
    [self importFromPath:path];
    
    return(self);
}

- (NSString *)name{
    return([path lastPathComponent]); //Large black drawer label
}
- (NSString *)collectionDescription{
    return([path lastPathComponent]); //Window title when collection is selected
}
- (NSString *)UID{
    return(@"ImportedContacts"); //Used to store group collapse/expand state
} 
- (BOOL)showOwnershipColumns{
    return(NO); //Display ownership/checkbox column?
}
- (BOOL)showCustomEditorColumns{
    return(NO);//Display custom columns (alias, ...)?
}
- (BOOL)includeInOwnershipColumn{
    return(NO);//Does this collection get a check box in the ownership column?
}
- (BOOL)showIndexColumn{
    return(NO);
}
- (NSString *)serviceID{
    return(@"AIM"); //All handles are of the service type of our imported file (AIM for now)
}
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"AllContacts" forClass:[self class]]); //Return our icon description
}
- (BOOL)enabled{
    return(YES); //Return YES if this collection is enabled
}

//used in the constructor
- (void)importFromPath:(NSString *)inPath
{
    [list release];
    list = [[self importContactsFromPath:inPath] retain];

    [self sortUsingMode:[self sortMode]];
}

//strips surrounding whitespace and quotes
- (NSString *)makeStringPretty:(NSString *)string
{
    //string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; //strip the whitespace  //this doesn't work!
    
    NSMutableString *tempMString = [[string mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)tempMString); //this does
    string = (NSString *)tempMString;
    
    if([string length] >= 1 && [string characterAtIndex:0] == '\"') //are there quotes?
    {
        string = [string substringWithRange:NSMakeRange(1,[string length]-2)]; //strip off the quotes
    }	
    return string;
}

//grab the contacts form a file and return them in a list group
- (NSMutableArray *)importContactsFromPath:(NSString *)inPath
{
    NSScanner *blt = [NSScanner scannerWithString:
                    [NSString stringWithContentsOfFile:inPath]];
    
    NSCharacterSet *whiteN = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *white = [NSCharacterSet whitespaceCharacterSet];
    
    NSString *value;
    
    AIEditorListGroup 	*currentGroup = nil;
    AIEditorListHandle 	*currentHandle = nil;
    
    BOOL inGroup = NO, end = NO;
    
    NSMutableArray *alist = [NSMutableArray array];

    [blt setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t"]];
    
    //gets us into the right place to start reading in the list.
    [blt scanUpToString:@"Buddy {" intoString:nil];
    [blt scanUpToString:@"list {" intoString:nil];
    [blt scanString:@"list {" intoString:nil];
    [blt scanCharactersFromSet:whiteN intoString:nil];
    
    while(!end)
    {
        if(!inGroup) //if we're not in a group, find the next one.
        {
            if(currentGroup)//we need to add the group, only if this is the 2nd time through
            {
                [alist addObject:currentGroup];
            }
            [blt scanUpToString:@"{" intoString:&value]; //get the group name
            
            if([[NSScanner scannerWithString:value] scanString:@"}" intoString:nil]) 
            //we're done, we closed the list{} thing!
            {
                end = YES;
            }
            else //we've found a group
            {
                value = [self makeStringPretty:value];
                currentGroup = [[[AIEditorListGroup alloc] initWithUID:value temporary:NO] autorelease]; //we need to set the current group.
                inGroup = YES;
            }
            
            [blt scanUpToCharactersFromSet:white intoString:nil];
            [blt scanString:@"{" intoString:nil]; //advance past the '{'
        }
        else //not in a group, so read in buddies
        {
            [blt scanCharactersFromSet:whiteN intoString:nil]; //get up to the name
            [blt scanUpToString:@"\r" intoString:&value]; //read in the whole line
                    
            value = [self makeStringPretty:value];
            
            if([value isEqual:@"}"])//we're done with this group
            {
                inGroup = NO;
            }
            else
            {
                currentHandle = [[[AIEditorListHandle alloc] initWithUID:value temporary:NO] autorelease];
                [currentGroup addHandle:currentHandle];
            }
        }
    }
    
    return alist;
}

@end
