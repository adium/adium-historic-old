//
//  GBApplescriptFiltersPlugin.m
//  Adium
//
//  Created by Gregory Barchard on Wed Dec 10 2003.
//

#import "GBApplescriptFiltersPlugin.h"

#define SCRIPT_BUNDLE_EXTENSION	@"AdiumScripts"
#define SCRIPTS_PATH_NAME		@"Scripts"
#define SCRIPT_EXTENSION		@"scpt"

@interface GBApplescriptFiltersPlugin (PRIVATE)
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu;
- (void)_sortScriptsByTitle:(NSMutableArray *)sortArray;
- (NSMutableArray *)_loadScriptsFromDirectory:(NSString *)dirPath intoUsageArray:(NSMutableArray *)useArray;
- (id)_filterString:(NSString *)inString originalObject:(id)originalObject;
- (NSString *)_executeScript:(NSDictionary *)infoDict withArguments:(NSArray *)arguments;
- (void)_replaceKeyword:(NSString *)keyword withScript:(NSDictionary *)infoDict inString:(NSString *)inString inAttributedString:(id)toObject;
- (NSArray *)_argumentsFromString:(NSString *)inString forScript:(NSDictionary *)scriptDict;
- (void)buildScriptMenu;
@end

int _scriptTitleSort(id scriptA, id scriptB, void *context);
int _scriptKeywordLengthSort(id scriptA, id scriptB, void *context);

@implementation GBApplescriptFiltersPlugin

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
	[self buildScriptMenu]; //this also sets the submenu for the menu item.

	[[adium menuController] addMenuItem:scriptMenuItem toLocation:LOC_Edit_Additions];
        [[adium menuController] addContextualMenuItem:[scriptMenuItem copy] toLocation:Context_TextView_Edit];
	
	//Perform substitutions on outgoing content
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
	
	//Observe for installation of new scripts
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
}

//Uninstall
- (void)uninstallPlugin
{
//	[[adium contentController] unregisterOutgoingContentFilter:self];
//	[[adium contentController] unregisterStringFilter:self];
	[scriptArray release]; scriptArray = nil;
    [flatScriptArray release]; flatScriptArray = nil;
	[scriptMenuItem release]; scriptMenuItem = nil;
}

- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumScripts"] == 0){
		[self buildScriptMenu]; 
	}
}


//Script Loading -------------------------------------------------------------------------------------------------------
#pragma mark Script Loading
//Load our scripts
- (void)loadScripts
{
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
					NSString		*scriptFileName, *scriptFilePath, *keyword, *title;
					NSArray			*arguments;
					NSURL			*scriptURL;
					NSNumber		*prefixOnlyNumber;
					NSNumber		*requiresUserInteractionNumber;
					
					if ((scriptFileName = [scriptDict objectForKey:@"File"]) &&
						(scriptFilePath = [scriptBundle pathForResource:scriptFileName
																 ofType:SCRIPT_EXTENSION])){
						
						scriptURL = [NSURL fileURLWithPath:scriptFilePath];
						keyword = [scriptDict objectForKey:@"Keyword"];
						title = [scriptDict objectForKey:@"Title"];
						
						if(scriptURL && keyword && [keyword length] && title && [title length]){
							NSMutableDictionary	*infoDict;
							
							arguments = [[scriptDict objectForKey:@"Arguments"] componentsSeparatedByString:@","];
							
							//Assume "Prefix Only" is NO unless told otherwise
							prefixOnlyNumber = [scriptDict objectForKey:@"Prefix Only"];
							if (!prefixOnlyNumber) prefixOnlyNumber = [NSNumber numberWithBool:NO];
							
							requiresUserInteractionNumber = [scriptDict objectForKey:@"Requires User Interaction"];
							if (!requiresUserInteractionNumber) requiresUserInteractionNumber = [NSNumber numberWithBool:NO];
							
							infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								scriptURL, @"Path", keyword, @"Keyword", title, @"Title", 
								prefixOnlyNumber, @"PrefixOnly", requiresUserInteractionNumber, @"RequiresUserInteraction",nil];
							
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
	}
	
	return(scripts);
}


//Script Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Script Menu
- (void)buildScriptMenu
{
	[self loadScripts];
	
	//Sort the scripts
	[scriptArray sortUsingFunction:_scriptTitleSort context:nil];
	[flatScriptArray sortUsingFunction:_scriptKeywordLengthSort context:nil];
	
	//Build the menu
	[scriptMenu release]; scriptMenu = [[NSMenu alloc] initWithTitle:SCRIPTS_MENU_NAME];
	[self _appendScripts:scriptArray toMenu:scriptMenu];
	[scriptMenuItem setSubmenu:scriptMenu];
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

//Sort by descending length so the longest keywords are at the beginning of the array
int _scriptKeywordLengthSort(id scriptA, id scriptB, void *context)
{
	NSComparisonResult result;
	
	unsigned int lengthA = [(NSString *)[scriptA objectForKey:@"Keyword"] length];
	unsigned int lengthB = [(NSString *)[scriptB objectForKey:@"Keyword"] length];
	if (lengthA > lengthB){
		result = NSOrderedAscending;
	}else if (lengthA < lengthB){
		result = NSOrderedDescending;
	}else{
		result = NSOrderedSame;
	}
	
	return result;
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
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
	//Append our string into the responder if possible
	if(responder && [responder isKindOfClass:[NSTextView class]]){
		NSArray		*arguments = [[sender representedObject] objectForKey:@"Arguments"];
		NSString	*replacementText = [[sender representedObject] objectForKey:@"Keyword"];
		
		[(NSTextView *)responder insertText:replacementText];
		
		//Append arg list to replacement string, to show the user what they can pass
		if(arguments){
			NSEnumerator		*argumentEnumerator = [arguments objectEnumerator];
			NSDictionary		*originalTypingAttributes = [(NSTextView *)responder typingAttributes];
			NSMutableDictionary *italicizedTypingAttributes = [originalTypingAttributes mutableCopy];
			NSString			*anArgument;
			BOOL				insertedFirst = NO;
			
			[italicizedTypingAttributes setObject:[[NSFontManager sharedFontManager] convertFont:[originalTypingAttributes objectForKey:NSFontAttributeName]
																					 toHaveTrait:NSItalicFontMask]
										   forKey:NSFontAttributeName];
			
			[(NSTextView *)responder insertText:@"{"];
			
			//Will that be a five minute argument or the full half hour?
			while (anArgument = [argumentEnumerator nextObject]){
				//Insert a comma after each argument past the first
				if (insertedFirst){
					[(NSTextView *)responder insertText:@","];					
				}else{
					insertedFirst = YES;
				}
				
				//Turn on the italics version, insert the argument, then go back to normal for either the comma or the ending
				[(NSTextView *)responder setTypingAttributes:italicizedTypingAttributes];
				[(NSTextView *)responder insertText:anArgument];
				[(NSTextView *)responder setTypingAttributes:originalTypingAttributes];
			}

			[(NSTextView *)responder insertText:@"}"];
			
			[italicizedTypingAttributes release];
		}
	}
}

//Just a target so we get the validateMenuItem: call for the script menu
-(IBAction)dummyTarget:(id)sender{
}

//Disable the insertion if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
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
    NSMutableAttributedString   *filteredMessage = nil;
	NSString					*stringMessage;

	if (stringMessage = [inAttributedString string]){
		NSEnumerator				*enumerator;
		NSDictionary				*infoDict;
		
		//Replace all keywords
		enumerator = [flatScriptArray objectEnumerator];
		while(infoDict = [enumerator nextObject]){
			NSString	*keyword = [infoDict objectForKey:@"Keyword"];
			BOOL		prefixOnly = [[infoDict objectForKey:@"PrefixOnly"] boolValue];

			if((prefixOnly && ([stringMessage rangeOfString:keyword options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0)) ||
			   (!prefixOnly && [stringMessage rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)){

				NSNumber	*shouldSendNumber;
				
				if(!filteredMessage) filteredMessage = [inAttributedString mutableCopy];
				[self _replaceKeyword:keyword withScript:infoDict inString:stringMessage inAttributedString:filteredMessage];
				stringMessage = [filteredMessage string]; //Update our plain text string, since it most likely changed
				
				shouldSendNumber = [infoDict objectForKey:@"ShouldSend"];
				if ((shouldSendNumber) &&
					(![shouldSendNumber boolValue]) &&
					([context isKindOfClass:[AIContentObject class]])){
					[(AIContentObject *)context setSendContent:NO];
				}
			}
		}
	}
	
    return(filteredMessage ? [filteredMessage autorelease] : inAttributedString);
}

//Perform a thorough variable replacing scan
- (void)_replaceKeyword:(NSString *)keyword withScript:(NSDictionary *)infoDict inString:(NSString *)inString inAttributedString:(NSMutableAttributedString *)attributedString
{
	NSScanner	*scanner;
	NSString	*arglessScriptResult = nil;
	int			offset = 0;
	
	if (inString) {
		scanner = [NSScanner scannerWithString:inString];
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
						argArray = [self _argumentsFromString:argString forScript:infoDict];
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
}

//Return an NSData for each argument in the string
- (NSArray *)_argumentsFromString:(NSString *)inString forScript:(NSDictionary *)scriptDict
{
	NSArray			*scriptArguments = [scriptDict objectForKey:@"Arguments"];
	NSMutableArray	*argArray = [NSMutableArray array];
	NSArray			*inStringComponents = [inString componentsSeparatedByString:@","];
	
	unsigned		i = 0;
	unsigned		count = (scriptArguments ? [scriptArguments count] : 0);
	unsigned		inStringComponentsCount = [inStringComponents count];
	
	//Add each argument of inString to argArray so long as the number of arguments is less
	//than the number of expected arguments for the script and the number of supplied arguments
	while((i < count) && (i < inStringComponentsCount)){
		[argArray addObject:[inStringComponents objectAtIndex:i]];
		i++;
	}
	
	//If more components were passed than were actually requested, the last argument gets the
	//remainder
	if (i < inStringComponentsCount){
		NSRange	remainingRange;
		
		//i was incremented to end the while loop if i > 0, so subtract 1 to reexamine the last object
		remainingRange.location = ((i > 0) ? i-1 : 0);
		remainingRange.length = (inStringComponentsCount - remainingRange.location);

		if (remainingRange.location >= 0){
			NSString	*lastArgument;

			//Remove that last, incomplete argument if it was added
			if ([argArray count]) [argArray removeLastObject];

			//Create the last argument by joining all remaining comma-separated arguments with a comma
			lastArgument = [[inStringComponents subarrayWithRange:remainingRange] componentsJoinedByString:@","];

			[argArray addObject:lastArgument];
		}
	}
	
	return(argArray);
}

//Execute the script, returning its output
- (NSString *)_executeScript:(NSDictionary *)infoDict withArguments:(NSArray *)arguments
{
	NSAppleScript   *script;
	NSString		*returnValue;
	
	script = [[NSAppleScript alloc] initWithContentsOfURL:[infoDict objectForKey:@"Path"]
													error:nil];
	
	//Running an applescript will take multiple run loops; it is not acceptable for our autorelease pool
	//to be released between these loops as we have autoreleased objects upon which we are depending
	[[adium contentController] setAllowFilterThreadAutoreleasePoolRefresh:NO];
	
	if([[infoDict objectForKey:@"RequiresUserInteraction"] boolValue]){
		NSAppleEventDescriptor	*eventDescriptor;
		NSInvocation			*invocation;
		NSString				*function = @"substitute";
		SEL						selector = @selector(executeFunction:withArguments:error:);
		
		invocation = [NSInvocation invocationWithMethodSignature:[script methodSignatureForSelector:selector]];
		[invocation setSelector:selector];
		[invocation setTarget:script];
		[invocation setArgument:&function atIndex:2];
		[invocation setArgument:&arguments atIndex:3];
		
		[invocation performSelectorOnMainThread:@selector(invoke)
									 withObject:nil
								  waitUntilDone:YES];
		
		[invocation getReturnValue:&eventDescriptor];
		returnValue = [[eventDescriptor stringValue] retain];
		
	}else{
		returnValue = [[[script executeFunction:@"substitute" withArguments:arguments error:nil] stringValue] retain];	
	}

	[script release];
	
	[[adium contentController] setAllowFilterThreadAutoreleasePoolRefresh:YES];
		
	return([returnValue autorelease]);
}

@end
