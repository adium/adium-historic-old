//
//  AIEditorImportCollection.m
//  Adium
//
//  Created by Colin Barrett on Sun Apr 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIEditorImportCollection.h"

@interface AIEditorImportCollection (PRIVATE)
- (id)init;
- (id)initWithPath:(NSString *)path;
- (void)importFromPath:(NSString *)path;
- (NSString *)makeStringPretty:(NSString *)string;
- (AIEditorListGroup *)importContactsFromPath:(NSString *)path;
@end

@implementation AIEditorImportCollection
//Return an empty collection 
+ (AIEditorImportCollection *)editorCollection
{
    return([[[self alloc] init] autorelease]);
}
//Retun collection from a path, set the name
+ (AIEditorImportCollection *)editorCollectionWithPath:(NSString *)path
{
    return([[[self alloc] initWithPath:path] autorelease]);
}
//empty initializer
- (id)init
{
    [super init];
    
    list = [[[AIEditorListGroup alloc] initWithUID:@"Self" temporary:NO] autorelease];
    
    return self;
}
//path initializer
- (id)initWithPath:(NSString *)path
{
    [super init];
        
    [self importFromPath:path];
    
    return self;
}
//Return our text description
- (NSString *)name
{
    return(@"Imported Contacts");
}

//Return our icon description
- (NSImage *)icon
{
    return([AIImageUtilities imageNamed:@"AllContacts" forClass:[self class]]);
}

//Return YES if this collection is enabled
- (BOOL)enabled
{
    return([list count] != 0);
}

//Return an Editor List Group containing everything in this collection
- (AIEditorListGroup *)list
{
    return(list);
}

//Add an object to the collection
- (void)addObject:(AIEditorListObject *)inObject
{
    //ignored
}

//Delete an object from the collection
- (void)deleteObject:(AIEditorListObject *)inObject
{
    //ignored
}

//Rename an existing object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName
{
    //ignored
}

//Move an existing object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup
{
    //ignored
}

- (void)importAndAppendContactsFromPath:(NSString *)path
{
    AIEditorListGroup *appendList = [self importContactsFromPath:path];
    
    NSEnumerator *appendListEnumerator;
    AIEditorListObject *anObject;
    
    if([list count] == 0)//no contacts in the first place!
    {
        list = appendList;
    }
    else // we need to append
    {
        appendListEnumerator = [appendList objectEnumerator];
        while(anObject = [appendListEnumerator nextObject])
        {
            NSLog(@"%s%@%s","adding ",[anObject UID]," to the master list");
            [list addObject:anObject]; //add the objects individually, we don't want one big group.
        }
    }
}

//used in the constructor
- (void)importFromPath:(NSString *)path
{
    list = [self importContactsFromPath:path];
}

//strips surrounding whitespace and quotes
- (NSString *)makeStringPretty:(NSString *)string
{
    /*string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; //strip the whitespace */ //this doesn't work!
    
    NSMutableString *tempMString = [[string mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)tempMString); //this does
    string = (NSString *)tempMString;
    
    if([string length] >= 1 && [string characterAtIndex:0] == '\"') //are there quotes?
    {
        string = [string substringWithRange:NSMakeRange(1,[string length]-1)]; //strip off the quotes
    }	
    return string;
}

//grab the contacts form a file and return them in a list group
- (AIEditorListGroup *)importContactsFromPath:(NSString *)path
{
    NSScanner *blt = [NSScanner scannerWithString:
                    [NSString stringWithContentsOfFile:path]];
    
    NSCharacterSet *whiteN = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *white = [NSCharacterSet whitespaceCharacterSet];
    
    NSString *value;
    
    AIEditorListGroup *currentGroup = nil;
    AIEditorListHandle *currentHandle = nil;
    
    BOOL inGroup = NO, end = NO;
    
    AIEditorListGroup *alist = [[[AIEditorListGroup alloc] initWithUID:@"Imported" temporary:NO] autorelease];

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
                currentHandle = [[[AIEditorListHandle alloc] initWithServiceID:@"AIM" UID:value temporary:NO] autorelease];
                [currentGroup addObject:currentHandle];
            }
        }
    }
    
    return alist;
}
@end
