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

/*!
@class ESSystemNetworkDefaults
@abstract Class to provide access to the systemwide network proxy settings
@discussion This class provides easy access to the systemwide network proxy settings of each type.
*/
@interface ESSystemNetworkDefaults : NSObject {

}

/*!
	@method systemProxySettingsDictionaryForType:
	@abstract Retrieve systemwide proxy settings for a type of proxy
	@discussion <p>Retrieve systemwide proxy settings for <b>proxyType</b>.</p>	
	@param proxyType The type of proxy for which to retrieve settings.  ProxyType should be one of Proxy_None, Proxy_HTTP, Proxy_HTTPS, Proxy_SOCKS4, Proxy_SOCKS5, Proxy_FTP, Proxy_RTSP, or Proxy_Gopher.
	@result	An <tt>NSDictionary</tt> containing the settings for that proxy type, or nil if no proxy is configured for that type.  The dictionary has the host as an NSString in the key @"Host", the port as an NSNumber in the key @"Port", and, if they are present, the username and password as NSStrings in @"Username" and @"Password" respectively.
*/
+ (NSDictionary *)systemProxySettingsDictionaryForType:(ProxyType)proxyType;

@end
