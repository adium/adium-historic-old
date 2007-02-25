//
//  adiumGaimDnsRequest.m
//  Adium
//
//  Created by Graham Booker on 2/24/07.
//

#import "adiumGaimDnsRequest.h"

@interface AdiumGaimDnsRequest : NSObject {
	GaimDnsQueryData *query_data;
	GaimDnsQueryResolvedCallback resolved_cb;
	GaimDnsQueryFailedCallback failed_cb;
	int success;
	GSList *returnData;
	int errorNumber;
	int cancel;
}
+ (AdiumGaimDnsRequest *)lookupRequestForData:(GaimDnsQueryData *)query_data;
- (id)initWithData:(GaimDnsQueryData *)data resolvedCB:(GaimDnsQueryResolvedCallback)resolved failedCB:(GaimDnsQueryFailedCallback)failed;
- (void)startLookup:(id)sender;
- (void)lookupComplete:(id)sender;
- (void)cancel;
@end

@implementation AdiumGaimDnsRequest

static NSMutableDictionary *threads = nil;

+ (void)initialize
{
	[super initialize];
	
	threads = [[NSMutableDictionary alloc] init];
}

+ (AdiumGaimDnsRequest *)lookupRequestForData:(GaimDnsQueryData *)query_data
{
	return [threads objectForKey:[NSValue valueWithPointer:query_data]];
}

- (id)initWithData:(GaimDnsQueryData *)data resolvedCB:(GaimDnsQueryResolvedCallback)resolved failedCB:(GaimDnsQueryFailedCallback)failed
{
	self = [super init];
	if(self == nil)
		return nil;
	
	query_data = data;
	resolved_cb = resolved;
	failed_cb = failed;
	success = 0;
	returnData = NULL;
	errorNumber = 0;
	cancel = 0;
	
	[threads setObject:self forKey:[NSValue valueWithPointer:query_data]];
	[self retain];  //Released in lookupComplete:
	[NSThread detachNewThreadSelector:@selector(startLookup:) toTarget:self withObject:nil];
	
	return self;
}

- (void)startLookup:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	struct addrinfo hints, *res, *tmp;
	char servname[20];
	
	g_snprintf(servname, sizeof(servname), "%d", gaim_dnsquery_get_port(query_data));
	memset(&hints, 0, sizeof(hints));
	
	/* This is only used to convert a service
	 * name to a port number. As we know we are
	 * passing a number already, we know this
	 * value will not be really used by the C
	 * library.
	 */
	hints.ai_socktype = SOCK_STREAM;
	errorNumber = getaddrinfo(gaim_dnsquery_get_host(query_data), servname, &hints, &res);
	if (errorNumber != 0) {
/*		if (show_debug)
			printf("dns[%d] Error: getaddrinfo returned %d\n",
				   getpid(), rc);
		dns_params.hostname[0] = '\0';*/
		success = 0;
	}
	else
	{
		returnData = NULL;
		tmp = res;
		while (res) {
			size_t addrlen = res->ai_addrlen;
			struct sockaddr *addr = g_malloc(addrlen);
			memcpy(addr, res->ai_addr, addrlen);
			returnData = g_slist_append(returnData, GINT_TO_POINTER(addrlen));
			returnData = g_slist_append(returnData, addr);
			res = res->ai_next;
		}
		freeaddrinfo(tmp);
		success = 1;
	}
	[self performSelectorOnMainThread:@selector(lookupComplete:) withObject:nil waitUntilDone:NO];
	[pool release];
}

- (void)lookupComplete:(id)sender
{
	if(cancel)
	{
		//We cancelled
		if(returnData != NULL)
		{
			GSList *hosts = returnData;
			while (hosts != NULL)
			{
				hosts = g_slist_remove(hosts, hosts->data);
				g_free(hosts->data);
				hosts = g_slist_remove(hosts, hosts->data);
			}
		}
	}
	else if(success)
	{
		resolved_cb(query_data, returnData);
	}
	else
	{
		char message[1024];
		
		g_snprintf(message, sizeof(message), _("Error resolving %s:\n%s"),
				   gaim_dnsquery_get_host(query_data), gai_strerror(errorNumber));
		failed_cb(query_data, message);
	}
	[self autorelease];  //Release our retain in init...
	if(query_data != NULL)
		//Can happen if we were cancelled
		[threads removeObjectForKey:[NSValue valueWithPointer:query_data]];
}

- (void)cancel
{
	//Can't stop an existing thread, so let it just die gracefully when it is done
	cancel = 1;
	
	//To avoid collitions and the like
	[threads removeObjectForKey:[NSValue valueWithPointer:query_data]];
	query_data = NULL;
}

@end

gboolean adiumGaimDnsRequestResolve(GaimDnsQueryData *query_data, GaimDnsQueryResolvedCallback resolved_cb, GaimDnsQueryFailedCallback failed_cb)
{
	[[[AdiumGaimDnsRequest alloc] initWithData:query_data resolvedCB:resolved_cb failedCB:failed_cb] autorelease];
	return TRUE;
}

void adiumGaimDnsRequestDestroy(GaimDnsQueryData *query_data)
{
	[[AdiumGaimDnsRequest lookupRequestForData:query_data] cancel];
}

static GaimDnsQueryUiOps adiumGaimDnsRequestOps = {
	adiumGaimDnsRequestResolve,
	adiumGaimDnsRequestDestroy
};

GaimDnsQueryUiOps *adium_gaim_dns_request_get_ui_ops(void)
{
	return &adiumGaimDnsRequestOps;
}
