//
//  CBGaimServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import <Security/Security.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "CBGaimServicePlugin.h"
#import "SLGaimCocoaAdapter.h"

#import "GaimServices.h"

@interface CBGaimServicePlugin (PRIVATE)
- (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key;
- (void)_initGaim;
- (void)configureSignals;
@end

/*
 * Maps GaimAccount*s to CBGaimAccount*s.
 * This is necessary because the gaim people didn't put the same void *ui_data
 * in here that they put in most of their other structures. Maybe we should
 * ask them for one so we can take this out.
 */
NSMutableDictionary *_accountDict;
static CBGaimServicePlugin  *servicePluginInstance;

@implementation CBGaimServicePlugin

- (void)_initGaim
{	
	/*
	//Handle libgaim events with the Cocoa event loop
	NSArray *portArray;
	NSPort  *port1,*port2;
	port1 = [NSPort port];
    port2 = [NSPort port];
    kitConnection = [[NSConnection alloc] initWithReceivePort:port1
													 sendPort:port2];
    [kitConnection setRootObject:self];
	
    // Ports switched here. 
    portArray = [NSArray arrayWithObjects:port2, port1, nil];

	[NSThread detachNewThreadSelector:@selector(createThreadedGaimCocoaAdapter:)
							 toTarget:[SLGaimCocoaAdapter class]
						   withObject:portArray];
	 */
//	 [SLGaimCocoaAdapter createThreadedGaimCocoaAdapter];
	[NSThread detachNewThreadSelector:@selector(createThreadedGaimCocoaAdapter)
							 toTarget:[SLGaimCocoaAdapter class]
						   withObject:nil];
}

- (void)setGaimThread:(id)gaimThread
{
	
}

#pragma mark Plugin Installation
//  Plugin Installation ------------------------------------------------------------------------------------------------

#define GAIM_DEFAULTS   @"GaimServiceDefaults"

- (void)installPlugin
{
	servicePluginInstance = self;

	//Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:GAIM_DEFAULTS forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
	
	_accountDict = [[NSMutableDictionary alloc] init];
	
	[self _initGaim];

    //Install the services
    OscarService	= [[[CBOscarService alloc] initWithService:self] retain];
    GaduGaduService = [[[ESGaduGaduService alloc] initWithService:self] retain];
    MSNService		= [[[ESMSNService alloc] initWithService:self] retain];
    NapsterService  = [[[ESNapsterService alloc] initWithService:self] retain];
	NovellService   = [[[ESNovellService alloc] initWithService:self] retain];
	JabberService   = [[[ESJabberService alloc] initWithService:self] retain];
	TrepiaService   = [[[ESTrepiaService alloc] initWithService:self] retain];
    YahooService	= [[[ESYahooService alloc] initWithService:self] retain];
	YahooJapanService = [[[ESYahooJapanService alloc] initWithService:self] retain];
}

- (void)uninstallPlugin
{
    [_accountDict release]; _accountDict = nil;
    
    //Services
    [OscarService release]; OscarService = nil;
    [GaduGaduService release]; GaduGaduService = nil;
	[JabberService release]; JabberService = nil;
    [NapsterService release]; NapsterService = nil;
    [MSNService release]; MSNService = nil;
	[TrepiaService release]; TrepiaService = nil;
    [YahooService release]; YahooService = nil;
	[YahooJapanService release]; YahooJapanService = nil;
	[NovellService release]; NovellService = nil;

	[kitConnection release]; kitConnection = nil;
}

#pragma mark AccountDict Methods
// AccountDict ---------------------------------------------------------------------------------------------------------
- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct 
{
    [_accountDict setObject:anAccount forKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccount:(GaimAccount *)gaimAcct
{
    [_accountDict removeObjectForKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccountWithPointerValue:(NSValue *)inPointer
{
    [_accountDict removeObjectForKey:inPointer];	
}

#pragma mark Systemwide Proxy Settings
// Proxy ---------------------------------------------------------------------------------------------------------------

- (NSDictionary *)systemSOCKSSettingsDictionary
{
	NSMutableDictionary *systemSOCKSSettingsDictionary = nil;
	
    Boolean             result;
    CFDictionaryRef     proxyDict = nil;
    CFNumberRef         enableNum = nil;
    int                 enable;
    CFStringRef         hostStr = nil;
    CFNumberRef         portNum = nil;
    int                 portInt;
    
    char    host[300];
    size_t  hostSize;
		
    proxyDict = SCDynamicStoreCopyProxies(NULL);
    result = (proxyDict != NULL);
     
    // Get the enable flag.  This isn't a CFBoolean, but a CFNumber.
    // Check if SOCKS is enabled
    if (result) {
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                       kSCPropNetProxiesSOCKSEnable);
        
        result = (enableNum != NULL)
            && (CFGetTypeID(enableNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(enableNum, kCFNumberIntType,
                                  &enable) && (enable != 0);
    }
    
    // Get the proxy host.  DNS names must be in ASCII.  If you 
    // put a non-ASCII character  in the "Secure Web Proxy"
    // field in the Network preferences panel, the CFStringGetCString
    // function will fail and this function will return false.
    if (result) {
		if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: SOCKS is enabled; looking up kSCPropNetProxiesSOCKSProxy");
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSProxy);
        
        result = (hostStr != NULL)
            && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, [NSString defaultCStringEncoding]);
		if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: got a host of %s",host);
    }
    
    //Get the proxy port
    if (result) {
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSPort);
        
        result = (portNum != NULL)
            && (CFGetTypeID(portNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(portNum, kCFNumberIntType, &portInt);
		if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: got a port of %i",portInt);
    }
    if (result) {
        //set what we've got so far
        if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: setting socks5 settings: %s:%i",host,portInt);
		
		NSString *hostString = [NSString stringWithCString:host];
				
		systemSOCKSSettingsDictionary = [[NSMutableDictionary alloc] init];
		
		[systemSOCKSSettingsDictionary setObject:hostString forKey:@"Host"];
		[systemSOCKSSettingsDictionary setObject:[NSNumber numberWithInt:portInt] forKey:@"Port"];
        
        NSDictionary* auth = [self getDictionaryFromKeychainForKey:hostString];
        
        if(auth) {
            if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: proxy username='%@' password=(in the keychain)",[auth objectForKey:@"username"]);
            
			[systemSOCKSSettingsDictionary setObject:[auth objectForKey:@"username"] forKey:@"Username"];
			[systemSOCKSSettingsDictionary setObject:[auth objectForKey:@"password"] forKey:@"Password"];
            
        } else {
            //No username/password.  I think this doesn't need to be an error or anythign since it should have been set in the system prefs
            if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: No username/password found");
        }
    }    
    
    // Clean up.
    if (proxyDict != NULL) {
        CFRelease(proxyDict);
    }
	
    return [systemSOCKSSettingsDictionary autorelease];
}    

//Next two functions are from the http-mail project.
static NSData *OWKCGetItemAttribute(KCItemRef item, KCItemAttr attrTag)
{
    SecKeychainAttribute    attr;
    OSStatus                keychainStatus;
    UInt32                  actualLength;
    void                    *freeMe = NULL;
    
    attr.tag = attrTag;
    actualLength = 256;
    attr.length = actualLength; 
    attr.data = alloca(actualLength);
    
    keychainStatus = KCGetAttribute(item, &attr, &actualLength);
    if (keychainStatus == errKCBufferTooSmall) {
        /* the attribute length will have been placed into actualLength */
        freeMe = NSZoneMalloc(NULL, actualLength);
        attr.length = actualLength;
        attr.data = freeMe;
        keychainStatus = KCGetAttribute(item, &attr, &actualLength);
    }
    if (keychainStatus == noErr) {
        NSData *retval = [NSData dataWithBytes:attr.data length:actualLength];
        if (freeMe != NULL)
            NSZoneFree(NULL, freeMe);
        return retval;
    }
    
    if (freeMe != NULL)
        NSZoneFree(NULL, freeMe);
    
    if (keychainStatus == errKCNoSuchAttr) {
        /* An expected error. Return nil for nonexistent attributes. */
        return nil;
    }
    
    /* We shouldn't make it here */
    [NSException raise:@"Error Reading Keychain" format:@"Error number %d.", keychainStatus];
    
    return nil;  // appease the dread compiler warning gods
}

- (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key
{
    NSData              *data;
    KCSearchRef         grepstate; 
    KCItemRef           item;
    UInt32              length;
    void                *itemData;
    NSMutableDictionary *result = nil;
    
    SecKeychainRef      keychain;
    SecKeychainCopyDefault(&keychain);
    
        if(KCFindFirstItem(keychain, NULL, &grepstate, &item)==noErr) {  
            do {
                NSString    *server = nil;
                
                data = OWKCGetItemAttribute(item, kSecLabelItemAttr);
                if(data) {
                    server = [NSString stringWithCString: [data bytes] length: [data length]];
                }
                
                if([key isEqualToString:server]) {
                    NSString    *username;
                    NSString    *password;
                    
                    data = OWKCGetItemAttribute(item, kSecAccountItemAttr);
                    if(data) {
                        username = [NSString stringWithCString: [data bytes] length: [data length]];
                    } else {
                        username = @"";
                    }
                    
                    if(SecKeychainItemCopyContent(item, NULL, NULL, &length, &itemData) == noErr) {
                        password = [NSString stringWithCString:itemData length:length];
                        SecKeychainItemFreeContent(NULL, itemData);
                    } else {
                        password = @"";
                    } 
                    
                    result = [NSDictionary dictionaryWithObjectsAndKeys:username,@"username",password,@"password",nil];
                    
                    KCReleaseItem(&item);
                    
                    break;
                }
                
                KCReleaseItem(&item);
            } while( KCFindNextItem(grepstate, &item)==noErr);
            
            KCReleaseSearch(&grepstate);
        }
    
        CFRelease(keychain);
    return result;   
}
@end