//
//  GBiTunerPlugin.m
//  Adium XCode
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#import "GBiTunerPlugin.h"
#import "GBiTunerPreferences.h"

#define PATH_INTERNAL_SCRIPTS	@"/Contents/Resources/Scripts/"
#define SCRIPT_PATH_EXTENSION	@"scpt"

@interface GBiTunerPlugin (PRIVATE)
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu atLevel:(int)level;
- (void)_sortScriptsByTitle:(NSMutableArray *)sortArray;
- (NSMutableArray *)_loadScriptsFromDirectory:(NSString *)dirPath intoUsageDict:(NSMutableDictionary *)useDict;
- (NSMenu *)loadScriptsAndBuildScriptMenu;
- (NSString*)hashLookup:(NSString *)pattern;
@end

int _scriptTitleSort(id scriptA, id scriptB, void *context);

@implementation GBiTunerPlugin

//install plugin
- (void)installPlugin
{
	NSMenuItem	*scriptMenuItem;
	
	//Init
	scriptDict = [[NSMutableDictionary alloc] init];
	scriptArray = [[NSMutableArray alloc] init];
	[[adium contentController] registerOutgoingContentFilter:self];

	//We have an array of scripts, which is used to build the menu.
	//Each entry in the array is a dict with the script's title and keyword
	scriptArray = [[NSMutableArray alloc] init];

	//We also have a dict for quick lookup and actual substitution with the scripts
	//The dict contains script paths with the keyword as their key
	scriptDict = [[NSMutableDictionary alloc] init];
	
	//Load all our scripts, and stick them in the script menu
	scriptMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Script" target:self action:nil keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:scriptMenuItem toLocation:LOC_Edit_Additions];
	[scriptMenuItem setSubmenu:[self loadScriptsAndBuildScriptMenu]];
}

//Load the scripts and build (returning) a script menu of them
- (NSMenu *)loadScriptsAndBuildScriptMenu
{
	NSMenu			*scriptMenu = [[NSMenu alloc] initWithTitle:@"Scripts"];
	NSString		*internalPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_SCRIPTS];
	NSMutableArray  *scripts;
	
	//Load the scripts, sort them, and stick them in our menu
	[scriptArray addObjectsFromArray:[self _loadScriptsFromDirectory:[internalPath stringByExpandingTildeInPath]
													   intoUsageDict:scriptDict]];
	[self _sortScriptsByTitle:scriptArray];
	[self _appendScripts:scriptArray toMenu:scriptMenu atLevel:0];

	return([scriptMenu autorelease]);
}

//Script Loading
- (NSMutableArray *)_loadScriptsFromDirectory:(NSString *)dirPath intoUsageDict:(NSMutableDictionary *)useDict
{
 	NSMutableArray		*scripts = [NSMutableArray array];
	NSEnumerator		*enumerator;
    NSString			*file;

	enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:dirPath] objectEnumerator];
    while((file = [enumerator nextObject])){
		if([[file lastPathComponent] characterAtIndex:0] != '.'){
			BOOL			isDirectory;
			NSString		*fullPath;
			
            fullPath = [dirPath stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
			if(isDirectory){
				//Load all the scripts within this directory
				[scripts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					@"Group", @"Type",
					[file lastPathComponent], @"Title",
					[self _loadScriptsFromDirectory:fullPath intoUsageDict:useDict], @"Content",
					nil]];
				
			}else{
				//Load this script
				NSURL			*scriptURL = [NSURL fileURLWithPath:fullPath];
				NSAppleScript   *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil] autorelease];
				NSString		*keyword = [[fullPath lastPathComponent] stringByDeletingPathExtension];
				
				//Place an entry in our scripts array, used for the script menu
				[scripts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					@"Script", @"Type",
					scriptURL, @"Path",
					keyword, @"Keyword",
					[[script executeFunction:@"title" error:nil] stringValue], @"Title",
					nil]];
				
				//Place an entry for this script in our usage dict, used for the text substitution
				[useDict setObject:scriptURL forKey:keyword];
			}
		}
	}

	return(scripts);
}

//Script Sorting
- (void)_sortScriptsByTitle:(NSMutableArray *)sortArray
{
	NSEnumerator	*enumerator;
	NSDictionary	*sortDict;
	
	//Sort the scripts
	[sortArray sortUsingFunction:_scriptTitleSort context:nil];
	
	//Sort the scripts of any subgroups
	enumerator = [sortArray objectEnumerator];
	while(sortDict = [enumerator nextObject]){
		if([(NSString *)[sortDict objectForKey:@"Type"] compare:@"Group"] == 0){
			[self _sortScriptsByTitle:[sortDict objectForKey:@"Content"]];
		}
	}
}
int _scriptTitleSort(id scriptA, id scriptB, void *context){
	return([(NSString *)[scriptA objectForKey:@"Title"] compare:[scriptB objectForKey:@"Title"]]);
}

//Script menu
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu atLevel:(int)level
{
	NSEnumerator	*enumerator;
	NSDictionary	*appendDict;
	
	enumerator = [scripts objectEnumerator];
	while(appendDict = [enumerator nextObject]){
		NSString	*type = [appendDict objectForKey:@"Type"];
		NSMenuItem	*item = nil;
		
		//Get the item
		if([type compare:@"Script"] == 0){
			NSString	*title;
			
			if([appendDict objectForKey:@"Title"]){
				title = [NSString stringWithFormat:@"%@ (%@)", [appendDict objectForKey:@"Title"], [appendDict objectForKey:@"Keyword"]];
			}else{
				title = [appendDict objectForKey:@"Keyword"];
			}
			
			NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:title
															target:self
															action:@selector(selectScript:)
													 keyEquivalent:@""] autorelease];

			[item setRepresentedObject:appendDict];
			if([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:level];
			[menu addItem:item];
			
		}else if([type compare:@"Group"] == 0){
			NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[appendDict objectForKey:@"Title"]
							target:nil
							action:nil
					 keyEquivalent:@""] autorelease];
			
			[item setRepresentedObject:appendDict];
			if([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:level];
			[menu addItem:item];

			//Add the items in this group
			[self _appendScripts:[appendDict objectForKey:@"Content"] toMenu:menu atLevel:level+1];
		}
						
	}
	
}

//Insert the selected script (CALL BY MENU ONLY)
- (IBAction)selectScript:(id)sender
{
	NSString	*keyword = [[sender representedObject] objectForKey:@"Keyword"];
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
	//Append our string into the responder if possible
	if(responder && [responder isKindOfClass:[NSTextView class]]){
		NSAttributedString	*attrString;
		
		//Use typing attributes if available
		if([responder respondsToSelector:@selector(typingAttributes)]){
			attrString = [[[NSAttributedString alloc] initWithString:keyword
														  attributes:[(NSTextView *)responder typingAttributes]] autorelease];
		}else{
			attrString = [[[NSAttributedString alloc] initWithString:keyword
														  attributes:[NSDictionary dictionary]] autorelease];
		}
		[[(NSTextView *)responder textStorage] appendAttributedString:attrString];
	}
}

//Disable the insertion if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	return(responder && [responder isKindOfClass:[NSText class]]);
}

//Filter messages for keywords to replace
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject
{
    NSMutableAttributedString   *mesg = nil;

    if(inAttributedString){
        NSString		*originalAttributedString = [inAttributedString string];
		NSEnumerator	*enumerator = [scriptDict keyEnumerator];
        NSString		*pattern;	
        
        //This loop gets run for every key in the dictionary
		while(pattern = [enumerator nextObject]){
            //if the original string contained this pattern
            if([originalAttributedString rangeOfString:pattern].location != NSNotFound){
			
				if(!mesg) mesg = [[inAttributedString mutableCopy] autorelease];   
                [mesg replaceOccurrencesOfString:pattern 
                                      withString:[self hashLookup:pattern] 
                                         options:NSLiteralSearch 
                                           range:NSMakeRange(0,[mesg length])];
            }
        }
    }
	
    return (mesg ? mesg : inAttributedString);
}

- (NSString *)hashLookup:(NSString *)pattern
{
    //@"" as the return string causes all sorts of problems because we can end up with a content message with no text
    //instead, default to a non-nil but one-length returnString - this way, the pattern is still removed
    //but problems are avoided.
    NSString        *returnString = @" ";
    
    NSURL *scriptURL = [scriptDict objectForKey:pattern];
    if(scriptURL){
        NSAppleScript   *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil] autorelease];
        returnString = [[script executeFunction:@"substitute" error:nil] stringValue];
    }
 
    return(returnString);	
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterOutgoingContentFilter:self];
    [scriptDict release];
	[scriptArray release];
}

@end
