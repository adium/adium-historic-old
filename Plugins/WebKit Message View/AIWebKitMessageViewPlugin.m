
#import "AIWebKitMessageViewPlugin.h"
#import "AIWebKitMessageViewController.h"

@interface AIWebKitMessageViewPlugin (PRIVATE)
- (void)_scanAvailableWebkitStyles;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName;
@end

@implementation AIWebKitMessageViewPlugin

- (void)installPlugin
{
	if(USE_WEBKIT_PLUGIN && [NSApp isOnPantherOrBetter]){
		//Init

		styleDictionary = nil;
		[self _scanAvailableWebkitStyles];
		
		//Setup our preferences
		[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]]
											  forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		preferences = [[ESWebKitMessageViewPreferences preferencePaneForPlugin:self] retain];
		advancedPreferences = [[ESWKMVAdvancedPreferences preferencePaneForPlugin:self] retain];
		
		//Observe for installation of new styles
		[[adium notificationCenter] addObserver:self
									   selector:@selector(xtrasChanged:)
										   name:Adium_Xtras_Changed
										 object:nil];
		
		//Register ourself as a message view plugin
		[[adium interfaceController] registerMessageViewPlugin:self];
		
		//Register our observers
//		[[adium contactController] registerListObjectObserver:self];
	}

	[adium createResourcePathForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat withPlugin:self]);
}

//Available Webkit Styles ----------------------------------------------------------------------------------------------
#pragma mark Available Webkit Styles
//Scan for available webkit styles (Call before trying to load/access a style)
- (void)_scanAvailableWebkitStyles
{	
	NSEnumerator	*enumerator, *fileEnumerator;
	NSString		*filePath, *resourcePath;
	NSArray			*resourcePaths;
	
	//Clear the current dictionary of styles and ready a new mutable dictionary
	[styleDictionary release];
	styleDictionary = [[NSMutableDictionary alloc] init];
	
	//Get all resource paths to search
	resourcePaths = [adium resourcePathsForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
	enumerator = [resourcePaths objectEnumerator];
	
	NSString	*AdiumMessageStyle = @"AdiumMessageStyle";
    while(resourcePath = [enumerator nextObject]) {
        fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
        
        //Find all the message styles
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:AdiumMessageStyle] == 0){
                NSBundle		*style;

				//Load the style and add it to our dictionary
				style = [NSBundle bundleWithPath:[resourcePath stringByAppendingPathComponent:filePath]];
				if(style){
					NSString	*styleName = [style name];
					if(styleName && [styleName length]) [styleDictionary setObject:style forKey:styleName];
				}
            }
        }
    }
}

//Returns a dictionary of available style identifiers and their paths
//- (NSDictionary *)availableStyles
- (NSDictionary *)availableStyleDictionary
{
	return(styleDictionary);
}

//Fetch the bundle for a message style by its bundle identifier
//- (NSBundle *)messageStyleBundleWithIdentifier:(NSString *)name
//{
//	return([NSBundle bundleWithPath:[styleDictionary objectForKey:name]]);
//}
- (NSBundle *)messageStyleBundleWithName:(NSString *)name
{
	return([styleDictionary objectForKey:name]);
}

//The default message style bundle
//- (NSBundle *)defaultMessageStyleBundle
//{
//	return([self messageStyleBundleWithIdentifier:MESSAGE_DEFAULT_STYLE]);
//}

//If the styles have changed, rebuild our list of available styles
- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumMessageStyle"] == 0){		
		[self _scanAvailableWebkitStyles];
		[preferences messageStyleXtrasDidChange];
	}
}

#pragma mark Available Webkit Styles

- (NSString *)variantKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Variant",desiredStyle];
}
- (NSString *)backgroundKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Background",desiredStyle];	
}
- (NSString *)backgroundColorKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Background Color",desiredStyle];
}

- (BOOL)boolForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant boolDefault:(BOOL)defaultValue
{
	NSNumber	*value = (NSNumber *)[self valueForKey:key style:style variant:variant];
	return (value ? [value boolValue] : defaultValue);
}

- (id)valueForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant
{
	id  value = [style objectForInfoDictionaryKey:[NSString stringWithFormat:@"%@:%@",key,variant]];
	if (!value){
		value = [style objectForInfoDictionaryKey:key];
	}
	return value;
}
@end
