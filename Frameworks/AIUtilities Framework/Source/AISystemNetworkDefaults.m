//
//  AISystemNetworkDefaults.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Jun 25 2004.

#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "AISystemNetworkDefaults.h"
#import "AIKeychain.h"

@implementation AISystemNetworkDefaults

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

	switch (proxyType) {
		case Proxy_HTTP: {
			enableKey = kSCPropNetProxiesHTTPEnable;
			portKey   = kSCPropNetProxiesHTTPPort;
			proxyKey  = kSCPropNetProxiesHTTPProxy;
			break;
		}
		case Proxy_SOCKS4:
		case Proxy_SOCKS5: {
			enableKey = kSCPropNetProxiesSOCKSEnable;
			portKey   = kSCPropNetProxiesSOCKSPort;
			proxyKey  = kSCPropNetProxiesSOCKSProxy;
			break;
		}
		case Proxy_HTTPS: {
			enableKey = kSCPropNetProxiesHTTPSEnable;
			portKey   = kSCPropNetProxiesHTTPSPort;
			proxyKey  = kSCPropNetProxiesHTTPSProxy;
			break;
		}
		case Proxy_FTP: {
			enableKey = kSCPropNetProxiesFTPEnable;
			portKey   = kSCPropNetProxiesFTPPort;
			proxyKey  = kSCPropNetProxiesFTPProxy;
			break;
		}
		case Proxy_RTSP: {
			enableKey = kSCPropNetProxiesRTSPEnable;
			portKey   = kSCPropNetProxiesRTSPPort;
			proxyKey  = kSCPropNetProxiesRTSPProxy;
			break;
		}
		case Proxy_Gopher: {
			enableKey = kSCPropNetProxiesGopherEnable;
			portKey   = kSCPropNetProxiesGopherPort;
			proxyKey  = kSCPropNetProxiesGopherProxy;
			break;
		}
		default: {
			return nil;
			break;
		}
	}

	if ((proxyDict = (NSDictionary *)SCDynamicStoreCopyProxies(NULL))) {

		//Enabled?
		enable = [[proxyDict objectForKey:(NSString *)enableKey] intValue];
		if (enable) {

			//Host
			hostString = [proxyDict objectForKey:(NSString *)proxyKey];
			if (hostString) {

				//Port
				portNum = [proxyDict objectForKey:(NSString *)portKey];
				if (portNum) {
					NSDictionary	*authDict;

					systemProxySettingsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						hostString, @"Host",
						portNum,    @"Port",
						nil];

					//User name & password if applicable
					NSError *error = nil;
					authDict = [[AIKeychain defaultKeychain_error:&error] dictionaryFromKeychainForServer:hostString error:&error];
					if (authDict) {
						[systemProxySettingsDictionary addEntriesFromDictionary:authDict];
					}
					if (error) {
						NSDictionary *userInfo = [error userInfo];
						NSLog(@"could not get username and password for proxy: %@ returned %i (%@)", [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], [error code], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
					}
				}
			}
		}
		// Could check and process kSCPropNetProxiesExceptionsList here, which returns: CFArray[CFString]

		//Clean up; proxyDict was created by a call with Copy in its name
		[proxyDict release];
	}


	return systemProxySettingsDictionary;
}

@end
