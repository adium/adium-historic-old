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
	NSDictionary		*proxyDict = nil;

	CFStringRef			enableKey;
    int                 enable;
    
	CFStringRef			portKey;
	NSNumber			*portNum = nil;

	CFStringRef			proxyKey;
	NSString			*hostString;
	
	switch(proxyType){
		case Proxy_HTTP: {
			enableKey = kSCPropNetProxiesHTTPEnable;
			portKey = kSCPropNetProxiesHTTPPort;
			proxyKey = kSCPropNetProxiesHTTPProxy;
			break;
		}
		case Proxy_SOCKS4:
		case Proxy_SOCKS5: {
			enableKey = kSCPropNetProxiesSOCKSEnable;
			portKey = kSCPropNetProxiesSOCKSPort;
			proxyKey = kSCPropNetProxiesSOCKSProxy;
			break;
		}
		case Proxy_HTTPS: {
			enableKey = kSCPropNetProxiesHTTPSEnable;
			portKey = kSCPropNetProxiesHTTPSPort;
			proxyKey = kSCPropNetProxiesHTTPSProxy;
			break;
		}
		case Proxy_FTP: {
			enableKey = kSCPropNetProxiesFTPEnable;
			portKey = kSCPropNetProxiesFTPPort;
			proxyKey = kSCPropNetProxiesFTPProxy;
			break;
		}
		case Proxy_RTSP: {
			enableKey = kSCPropNetProxiesRTSPEnable;
			portKey = kSCPropNetProxiesRTSPPort;
			proxyKey = kSCPropNetProxiesRTSPProxy;
			break;
		}
		case Proxy_Gopher: {
			enableKey = kSCPropNetProxiesGopherEnable;
			portKey = kSCPropNetProxiesGopherPort;
			proxyKey = kSCPropNetProxiesGopherProxy;
			break;
		}
		default: {
			return nil;
			break;
		}
	}
	
    if (proxyDict = (NSDictionary *)SCDynamicStoreCopyProxies(NULL)) {
		
		//Enabled?
		enable = [[proxyDict objectForKey:(NSString *)enableKey] intValue];
		if (enable){
			
			//Host
			hostString = [proxyDict objectForKey:(NSString *)proxyKey];
			if (hostString){
				
				//Port
				portNum = [proxyDict objectForKey:(NSString *)portKey];
				if (portNum){
					NSDictionary	*authDict;
		
					systemProxySettingsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						hostString,@"Host",
						portNum,@"Port",nil];
		
					//User name & password if applicable
					authDict = [AIKeychain getDictionaryFromKeychainForKey:hostString];
					if(authDict){
						[systemProxySettingsDictionary setObject:[authDict objectForKey:@"username"]
														  forKey:@"Username"];
						[systemProxySettingsDictionary setObject:[authDict objectForKey:@"password"]
														  forKey:@"Password"];
					}
				}
			}
		}
		// Could check and process kSCPropNetProxiesExceptionsList here, which returns: CFArray[CFString]
	}
    
    //Clean up; proxyDict was created by a call with Copy in its name
    if (proxyDict != NULL) {
        [proxyDict release];
    }

    return(systemProxySettingsDictionary);
}    

@end
