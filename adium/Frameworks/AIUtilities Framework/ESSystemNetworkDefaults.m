//
//  ESSystemNetworkDefaults.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Jun 25 2004.

#import "ESSystemNetworkDefaults.h"
#import <SystemConfiguration/SystemConfiguration.h>
#include <CoreServices/CoreServices.h>
#include <CoreFoundation/CoreFoundation.h>

@implementation ESSystemNetworkDefaults

+ (NSDictionary *)systemProxySettingsDictionaryForType:(ProxyType)proxyType
{
	NSMutableDictionary *systemProxySettingsDictionary = nil;
	CFDictionaryRef     proxyDict = nil;
	
    Boolean             result;
    	
	const CFStringRef*  enableKey;
	CFNumberRef         enableNum = nil;
    int                 enable;
    
	const CFStringRef*  portKey;
	CFNumberRef         portNum = nil;
    int                 portInt;

	const CFStringRef*  proxyKey;
	CFStringRef         hostStr = nil;
    char				host[300];
    size_t				hostSize;
	
	switch(proxyType){
		case Proxy_HTTP: {
			enableKey = &kSCPropNetProxiesHTTPEnable;
			portKey = &kSCPropNetProxiesHTTPPort;
			proxyKey = &kSCPropNetProxiesHTTPProxy;
			break;
		}
		case Proxy_SOCKS4:
		case Proxy_SOCKS5: {
			enableKey = &kSCPropNetProxiesSOCKSEnable;
			portKey = &kSCPropNetProxiesSOCKSPort;
			proxyKey = &kSCPropNetProxiesSOCKSProxy;
			break;
		}
		case Proxy_HTTPS: {
			enableKey = &kSCPropNetProxiesHTTPSEnable;
			portKey = &kSCPropNetProxiesHTTPSPort;
			proxyKey = &kSCPropNetProxiesHTTPSProxy;
			break;
		}
		case Proxy_FTP: {
			enableKey = &kSCPropNetProxiesFTPEnable;
			portKey = &kSCPropNetProxiesFTPPort;
			proxyKey = &kSCPropNetProxiesFTPProxy;
			break;
		}
		case Proxy_RTSP: {
			enableKey = &kSCPropNetProxiesRTSPEnable;
			portKey = &kSCPropNetProxiesRTSPPort;
			proxyKey = &kSCPropNetProxiesRTSPProxy;
			break;
		}
		case Proxy_Gopher: {
			enableKey = &kSCPropNetProxiesGopherEnable;
			portKey = &kSCPropNetProxiesGopherPort;
			proxyKey = &kSCPropNetProxiesGopherProxy;
			break;
		}
		default: {
			return nil;
			break;
		}
	}
	
	proxyDict = SCDynamicStoreCopyProxies(NULL);
    result = (proxyDict != NULL);
	
    // Get the enable flag.  This isn't a CFBoolean, but a CFNumber.
    // Check if SOCKS is enabled
    if (result) {
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict, *enableKey);
        
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
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict, *proxyKey);
        
        result = (hostStr != NULL)
            && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, [NSString defaultCStringEncoding]);
    }
    
    //Get the proxy port
    if (result) {
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict, *portKey);
        
        result = (portNum != NULL)
            && (CFGetTypeID(portNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(portNum, kCFNumberIntType, &portInt);
    }
    if (result) {
		NSString		*hostString = [NSString stringWithCString:host];
		NSDictionary	*authDict = [AIKeychain getDictionaryFromKeychainForKey:hostString];
		
		systemProxySettingsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			hostString,@"Host",
			[NSNumber numberWithInt:portInt],@"Port",nil];
		
        if(authDict) {            
			[systemProxySettingsDictionary setObject:[authDict objectForKey:@"username"] forKey:@"Username"];
			[systemProxySettingsDictionary setObject:[authDict objectForKey:@"password"] forKey:@"Password"];
            
        } else {
            //No username/password.  I think this doesn't need to be an error or anything since it should have been set in the system prefs
        }
		
		// Could check and process kSCPropNetProxiesExceptionsList here, which returns: CFArray[CFString]
    }    
    
    //Clean up
    if (proxyDict != NULL) {
        CFRelease(proxyDict);
    }
	
    return systemProxySettingsDictionary;
}    

@end
