//
//  GBiTunerPlugin.m
//  Adium
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#import "GBiTunerPlugin.h"

#define PATH_INTERNAL_SCRIPTS	@"/Contents/Resources/Scripts/"
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
#define PATH_EXTERNAL_SCRIPTS   [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Scripts"]
#define SCRIPT_PATH_EXTENSION	@"scpt"

@interface GBiTunerPlugin (PRIVATE)
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu atLevel:(int)level;
- (void)_sortScriptsByTitle:(NSMutableArray *)sortArray;
- (NSMutableArray *)_loadScriptsFromDirectory:(NSString *)dirPath intoUsageArray:(NSMutableArray *)useArray;
- (id)_filterString:(NSString *)inString originalObject:(id)originalObject;
- (NSString *)_executeScript:(NSDictionary *)infoDict withArguments:(NSArray *)arguments;
- (void)_replaceKeyword:(NSString *)keyword withScript:(NSDictionary *)infoDict inString:(NSString *)inString inAttributedString:(id)toObject;
- (NSArray *)_argumentsFromString:(NSString *)inString;
- (void)buildScriptMenu;
@end

int _scriptTitleSort(id scriptA, id scriptB, void *context);

@implementation GBiTunerPlugin

//Install plugin
- (void)installPlugin
{
	//User scripts
	[[AIObject sharedAdiumInstance] createResourcePathForName:@"Scripts"];
	
	//We have an array of scripts for building the menu, and a dictionary of scripts used for the actual substition
	scriptArray = nil;
	flatScriptArray = nil;
	
	//Prepare our script menu item (which will have the Scripts menu as its submenu)
	scriptMenuItem = [[NSMenuItem alloc] initWithTitle:SCRIPTS_MENU_NAME target:self action:@selector(dummyTarget:) keyEquivalent:@""];

	//Start building the script menu
	scriptMenu = nil;
	buildingScriptMenu = YES;
	[self buildScriptMenu]; //this also sets the submenu for the menu item.
    //[NSThread detachNewThreadSelector:@selector(_buildScriptMenuThread) toTarget:self withObject:nil];

	[[adium menuController] addMenuItem:scriptMenuItem toLocation:LOC_Edit_Additions];
	
	//Perform substitutions on outgoing content
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
}

//Uninstall
- (void)uninstallPlugin
{
//	[[adium contentController] unregisterOutgoingContentFilter:self];
//	[[adium contentController] unregisterStringFilter:self];
	[scriptArray release];
    [flatScriptArray release];
	[scriptMenuItem release];
}


//Script Loading -------------------------------------------------------------------------------------------------------
#pragma mark Script Loading
//Load our scripts
- (void)loadScripts
{
//	NSString		*internalPath = [[[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:PATH_INTERNAL_SCRIPTS] stringByExpandingTildeInPath];
	NSEnumerator	*enumerator;
	NSString 		*path;
	
	//
	[scriptArray release]; scriptArray = [[NSMutableArray alloc] init];
	[flatScriptArray release]; flatScriptArray = [[NSMutableArray alloc] init];
	
	//Load scripts
	enumerator = [[adium resourcePathsForName:@"Scripts"] objectEnumerator];
	while(path = [enumerator nextObject]){
		[scriptArray addObjectsFromArray:[self _loadScriptsFromDirectory:path intoUsageArray:flatScriptArray]];
	}
}

//Load a subset of scripts
- (NSMutableArray *)_loadScriptsFromDirectory:(NSString *)dirPath intoUsageArray:(NSMutableArray *)useArray
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
					[self _loadScriptsFromDirectory:fullPath intoUsageArray:useArray], @"Content",
					nil]];
				
			}else{
				//Load this script
				NSURL			*scriptURL = [NSURL fileURLWithPath:fullPath];
				NSAppleScript   *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil] autorelease];
				NSString		*keyword = [[script executeFunction:@"keyword" error:nil] stringValue];
				NSString		*title = [[script executeFunction:@"title" error:nil] stringValue];
				NSString		*arguments = [[script executeFunction:@"arguments" error:nil] stringValue];
				BOOL			prefixOnly = [[script executeFunction:@"prefixonly" error:nil] booleanValue];
				
				if(keyword && [keyword length] && title && [title length]){
					NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Script", @"Type",
						scriptURL, @"Path", keyword, @"Keyword", title, @"Title", 
						[NSNumber numberWithBool:prefixOnly], @"PrefixOnly", arguments, @"Arguments", nil];
					
					//Place the entry in our script arrays
					[scripts addObject:infoDict];
					[useArray addObject:infoDict];
				}
			}
		}
	}
	
	return(scripts);
}


//Script Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Script Menu
//Build the script menu
- (void)_buildScriptMenuThread
{	
	[NSThread setThreadPriority:0.0];
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self buildScriptMenu];
	
	[pool release];
}

- (void)buildScriptMenu
{
	if(!scriptArray) [self loadScripts];
	
	//Sort the scripts
	[self _sortScriptsByTitle:scriptArray];
	
	//Build the menu
	[scriptMenu release]; scriptMenu = [[NSMenu alloc] initWithTitle:SCRIPTS_MENU_NAME];
	[self _appendScripts:scriptArray toMenu:scriptMenu atLevel:0];
	[scriptMenuItem setSubmenu:scriptMenu];
	
	buildingScriptMenu = NO;
}

//Alphabetize scripts
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

//Append menu items for the scripts to a menu
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu atLevel:(int)level
{
	NSEnumerator	*enumerator;
	NSDictionary	*appendDict;
	
	enumerator = [scripts objectEnumerator];
	while(appendDict = [enumerator nextObject]){
		NSString	*type = [appendDict objectForKey:@"Type"];
		
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
	NSString	*replacementText = [[sender representedObject] objectForKey:@"Keyword"];
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	NSString	*arguments = [[sender representedObject] objectForKey:@"Arguments"];
	
	//Append arg list to replacement string, to show the user what they can pass
	if(arguments){
		replacementText = [NSString stringWithFormat:@"%@%@", replacementText, arguments];
	}
	
	//Append our string into the responder if possible
	if(responder && [responder isKindOfClass:[NSTextView class]]){
		NSAttributedString	*attrString;
		
		//Use typing attributes if available
		if([responder respondsToSelector:@selector(typingAttributes)]){
			attrString = [[[NSAttributedString alloc] initWithString:replacementText
														  attributes:[(NSTextView *)responder typingAttributes]] autorelease];
		}else{
			attrString = [[[NSAttributedString alloc] initWithString:replacementText
														  attributes:[NSDictionary dictionary]] autorelease];
		}
		[[(NSTextView *)responder textStorage] appendAttributedString:attrString];
	}
}

//Just a target so we get the validateMenuItem: call for the script menu
-(IBAction)dummyTarget:(id)sender{
}

//Disable the insertion if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if(!scriptMenu){
		if (buildingScriptMenu){
			while(buildingScriptMenu);
		}else{
			[self buildScriptMenu];
		}
	}

	if(menuItem == scriptMenuItem){
		return(YES); //Always keep the submenu enabled so users can see the available scripts
	}else{
		NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if(responder && [responder isKindOfClass:[NSText class]]){
                    return [(NSText *)responder isEditable];
                }else{
                    return NO;
                }
	}
}


//Message Filtering ----------------------------------------------------------------------------------------------------
#pragma mark Message Filtering
//Filter messages for keywords to replace
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	NSString					*stringMessage = [inAttributedString string];
    NSMutableAttributedString   *filteredMessage = nil;
	NSEnumerator				*enumerator;
	NSDictionary				*infoDict;

	//Ensure scripts have loaded
	if(!scriptMenu){
		if(buildingScriptMenu){
			while(buildingScriptMenu);
		}else{
			[self buildScriptMenu];
		}
	}
	
	//Replace all keywords
	enumerator = [flatScriptArray objectEnumerator];
	while(infoDict = [enumerator nextObject]){
		NSString	*keyword = [infoDict objectForKey:@"Keyword"];
		BOOL		prefixOnly = [[infoDict objectForKey:@"PrefixOnly"] boolValue];
		
		if((prefixOnly && [stringMessage hasPrefix:keyword]) ||
		   (!prefixOnly && [stringMessage rangeOfString:keyword].location != NSNotFound)){
			
			if(!filteredMessage) filteredMessage = [[inAttributedString mutableCopy] autorelease];
			[self _replaceKeyword:keyword withScript:infoDict inString:stringMessage inAttributedString:filteredMessage];
			stringMessage = [filteredMessage string]; //Update our plain text string, since it most likely changed
		}
	}
	
    return(filteredMessage ? filteredMessage : inAttributedString);
}

//Perform a thorough variable replacing scan
- (void)_replaceKeyword:(NSString *)keyword withScript:(NSDictionary *)infoDict inString:(NSString *)inString inAttributedString:(NSMutableAttributedString *)attributedString
{
	NSScanner	*scanner = [NSScanner scannerWithString:inString];
	NSString	*arglessScriptResult = nil;
	int			offset = 0;
	
	//Scan for the keyword
	while(![scanner isAtEnd]){
		[scanner scanUpToString:keyword intoString:nil];
		if([scanner scanString:keyword intoString:nil]){
			int 		keywordStart, keywordEnd;
			NSArray 	*argArray = nil;
			NSString	*argString;
			
			//Scan arguments
			keywordStart = [scanner scanLocation] - [keyword length];
			if([scanner scanString:@"{" intoString:nil]){				
				if([scanner scanUpToString:@"}" intoString:&argString]){
					argArray = [self _argumentsFromString:argString];
					[scanner scanString:@"}" intoString:nil];
				}
			}
			keywordEnd = [scanner scanLocation];		

			if(keywordStart != 0 && [inString characterAtIndex:keywordStart - 1] == '\\'){
				//Ignore the script (It was escaped), and delete the escape character
				[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset - 1, 1) withString:@""];
				offset -= 1;
				
			}else{
				//Run the script.  Cache the result to speed up multiple instances of a single keyword
				NSString	*scriptResult = nil;
				if([argArray count] == 0 && arglessScriptResult) scriptResult = arglessScriptResult;
				if(!scriptResult) scriptResult = [self _executeScript:infoDict withArguments:argArray];
				if([argArray count] == 0 && !arglessScriptResult) arglessScriptResult = scriptResult;
				
				//If the script fails, eat the keyword
				if(!scriptResult) scriptResult = @"";
				
				//Replace the substring with script result
				[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset, keywordEnd - keywordStart)
												withString:scriptResult];
				//Adjust for replaced text
				offset += [scriptResult length] - (keywordEnd - keywordStart);
				
			}
		}
	}
}

//Return an NSData for each argument in the string
- (NSArray *)_argumentsFromString:(NSString *)inString
{
	NSMutableArray	*argArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[inString componentsSeparatedByString:@","] objectEnumerator];
	NSString		*arg;
	
	while(arg = [enumerator nextObject]) {
		[argArray addObject:[arg dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return(argArray);
}

//Execute the script, returning it's output
- (NSString *)_executeScript:(NSDictionary *)infoDict withArguments:(NSArray *)arguments
{
	NSURL 			*scriptURL = [infoDict objectForKey:@"Path"];
	NSAppleScript   *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil] autorelease];

	return([[script executeFunction:@"substitute" withArguments:arguments error:nil] stringValue]);
}

@end
