//
//  GBiTunerPlugin.m
//  Adium
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#import "GBiTunerPlugin.h"

#define SCRIPT_BUNDLE_EXTENSION	@"AdiumScripts"
#define SCRIPTS_PATH_NAME		@"Scripts"
#define SCRIPT_EXTENSION		@"scpt"

@interface GBiTunerPlugin (PRIVATE)
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu;
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
	NSEnumerator		*fileEnumerator;
    NSString			*filePath;
	NSBundle			*scriptBundle;
	NSString			*AdiumScripts = SCRIPT_BUNDLE_EXTENSION;
	
	fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:dirPath] objectEnumerator];
	
	//Find all the script bundles at this path
	while((filePath = [fileEnumerator nextObject])){

		if([[filePath pathExtension] caseInsensitiveCompare:AdiumScripts] == 0){

			if(scriptBundle = [NSBundle bundleWithPath:[dirPath stringByAppendingPathComponent:filePath]]){
				
				NSString		*scriptsSetName;
				NSEnumerator	*scriptEnumerator;
				NSDictionary	*scriptDict;
				
				//Get the name of the set these scripts will go into
				scriptsSetName = [scriptBundle objectForInfoDictionaryKey:@"Set"];
				
				//Now enumerate each script the bundle claims as its own
				scriptEnumerator = [[scriptBundle objectForInfoDictionaryKey:@"Scripts"] objectEnumerator];
				
				while (scriptDict = [scriptEnumerator nextObject]){
					NSString		*scriptFileName, *keyword, *title, *arguments;
					NSURL			*scriptURL;
					NSNumber		*prefixOnlyNumber;
					
					scriptFileName = [scriptDict objectForKey:@"File"];
					scriptURL = [NSURL fileURLWithPath:[scriptBundle pathForResource:scriptFileName
																			  ofType:SCRIPT_EXTENSION]];
					keyword = [scriptDict objectForKey:@"Keyword"];
					title = [scriptDict objectForKey:@"Title"];
					
					if(scriptURL && keyword && [keyword length] && title && [title length]){
						NSMutableDictionary	*infoDict;
						
						arguments = [scriptDict objectForKey:@"Arguments"];
						
						//Assume "Prefix Only" is NO unless told otherwise
						prefixOnlyNumber = [scriptDict objectForKey:@"Prefix Only"];
						if (!prefixOnlyNumber) prefixOnlyNumber = [NSNumber numberWithBool:NO];
						
						infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							scriptURL, @"Path", keyword, @"Keyword", title, @"Title", 
							prefixOnlyNumber, @"PrefixOnly", nil];
						
						//The bundle may not be part of (or for defining) a set of scripts
						if (scriptsSetName){
							[infoDict setObject:scriptsSetName forKey:@"Set"];
						}
						//Arguments may be nil
						if (arguments){
							[infoDict setObject:arguments forKey:@"Arguments"];
						}

						//Place the entry in our script arrays
						[scripts addObject:infoDict];
						[useArray addObject:infoDict];
					}
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
	[scriptArray sortUsingFunction:_scriptTitleSort context:nil];
	
	//Build the menu
	[scriptMenu release]; scriptMenu = [[NSMenu alloc] initWithTitle:SCRIPTS_MENU_NAME];
	[self _appendScripts:scriptArray toMenu:scriptMenu];
	[scriptMenuItem setSubmenu:scriptMenu];
	
	buildingScriptMenu = NO;
}

//Sort first by set, then by title within sets
int _scriptTitleSort(id scriptA, id scriptB, void *context){
	NSComparisonResult result;
	
	NSString	*setA = [scriptA objectForKey:@"Set"];
	NSString	*setB = [scriptB objectForKey:@"Set"];
	
	if (setA && setB){
		
		//If both are within sets, sort by set; if they are within the same set, sort by title
		if ((result = [setA caseInsensitiveCompare:setB]) == NSOrderedSame){
			result = [(NSString *)[scriptA objectForKey:@"Title"] caseInsensitiveCompare:[scriptB objectForKey:@"Title"]];
		}
	}else{
		//Sort by title if neither is in a set; otherwise sort the one in a set to the top
		
		if (!setA && !setB){
			result = [(NSString *)[scriptA objectForKey:@"Title"] caseInsensitiveCompare:[scriptB objectForKey:@"Title"]];
		
		}else if (!setA){
			result = NSOrderedDescending;
		}else{
			result = NSOrderedAscending;
		}
	}
	
	return(result);
}

//Append menu items for the scripts to a menu; the array scripts must already have been 
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu
{
	NSEnumerator	*enumerator;
	NSDictionary	*appendDict;
	NSString		*lastSet = nil;
	NSString		*set;
	int				indentationLevel;
	
	enumerator = [scripts objectEnumerator];
	while(appendDict = [enumerator nextObject]){
		NSString	*title;
		NSMenuItem	*item;
		
		if (set = [appendDict objectForKey:@"Set"]){
			indentationLevel = 1;
			
			if (![set isEqualToString:lastSet]){
				//We have a new set of scripts; create a section header for them
				item = [[[NSMenuItem alloc] initWithTitle:set
																target:nil
																action:nil
														 keyEquivalent:@""] autorelease];
				if([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:0];
				[menu addItem:item];
				
				[lastSet release]; lastSet = [set retain];
			}
		}else{
			//Scripts not in sets need not be indented
			indentationLevel = 0;
			[lastSet release]; lastSet = nil;
		}
	
		if([appendDict objectForKey:@"Title"]){
			title = [NSString stringWithFormat:@"%@ (%@)", [appendDict objectForKey:@"Title"], [appendDict objectForKey:@"Keyword"]];
		}else{
			title = [appendDict objectForKey:@"Keyword"];
		}
		
		item = [[[NSMenuItem alloc] initWithTitle:title
										   target:self
										   action:@selector(selectScript:)
									keyEquivalent:@""] autorelease];
		
		[item setRepresentedObject:appendDict];
		if([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:indentationLevel];
		[menu addItem:item];
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
		
		if((prefixOnly && ([stringMessage compare:keyword options:(NSCaseInsensitiveSearch | NSAnchoredSearch)] == NSOrderedSame)) ||
		   (!prefixOnly && [stringMessage rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)){
			
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
				//Ignore the script (It was escaped) and delete the escape character
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
				if (([scriptResult hasPrefix:@"<HTML>"])){
					NSAttributedString *attributedScriptResult = [AIHTMLDecoder decodeHTML:scriptResult];
					[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset, keywordEnd - keywordStart)
													withAttributedString:attributedScriptResult];

				}else{
					[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset, keywordEnd - keywordStart)
													withString:scriptResult];
				}
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
