//
//  ESSystemNetworkDefaults.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Jun 25 2004.

//Proxy types
typedef enum
{
	Proxy_None		= 0,
	Proxy_HTTP		= 1,
	Proxy_HTTPS		= 2,
	Proxy_SOCKS4	= 3,
	Proxy_SOCKS5	= 4,
	Proxy_FTP		= 5,
	Proxy_RTSP		= 6,
	Proxy_Gopher	= 7
} ProxyType;

@interface ESSystemNetworkDefaults : NSObject {

}

+ (NSDictionary *)systemProxySettingsDictionaryForType:(ProxyType)proxyType;

@end
