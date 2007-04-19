//
//  adiumPurpleDnsRequest.m
//  Adium
//
//  Created by Graham Booker on 2/24/07.
//

#import "adiumPurpleDnsRequest.h"

@interface adiumPurpleDnsRequest : NSObject {
	PurpleDnsQueryData *query_data;
	PurpleDnsQueryResolvedCallback resolved_cb;
	PurpleDnsQueryFailedCallback failed_cb;
	int errorNumber;
	BOOL cancel;
}
+ (adiumPurpleDnsRequest *)lookupRequestForData:(PurpleDnsQueryData *)query_data;
- (id)initWithData:(PurpleDnsQueryData *)data resolvedCB:(PurpleDnsQueryResolvedCallback)resolved failedCB:(PurpleDnsQueryFailedCallback)failed;
- (void)startLookup:(id)sender;
- (void)lookupComplete:(NSValue *)resValue;
- (void)cancel;
@end

@implementation adiumPurpleDnsRequest

static NSMutableDictionary *threads = nil;

+ (void)initialize
{
	[super initialize];
	
	threads = [[NSMutableDictionary alloc] init];
}

+ (adiumPurpleDnsRequest *)lookupRequestForData:(PurpleDnsQueryData *)query_data
{
	return [threads objectForKey:[NSValue valueWithPointer:query_data]];
}

- (id)initWithData:(PurpleDnsQueryData *)data resolvedCB:(PurpleDnsQueryResolvedCallback)resolved failedCB:(PurpleDnsQueryFailedCallback)failed
{
	self = [super init];
	if(self == nil)
		return nil;
	
	query_data = data;
	resolved_cb = resolved;
	failed_cb = failed;
	errorNumber = 0;
	cancel = FALSE;
	
	[threads setObject:self forKey:[NSValue valueWithPointer:query_data]];
	[self retain];  //Released in lookupComplete:
	[NSThread detachNewThreadSelector:@selector(startLookup:) toTarget:self withObject:nil];
	
	return self;
}

- (void)startLookup:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	struct addrinfo hints, *res;
	char servname[20];
    BOOL success = FALSE;
	
	AILog(@"Performing DNS resolve: %s:%d",purple_dnsquery_get_host(query_data),purple_dnsquery_get_port(query_data));
	g_snprintf(servname, sizeof(servname), "%d", purple_dnsquery_get_port(query_data));
	memset(&hints, 0, sizeof(hints));
	
	/* This is only used to convert a service
	 * name to a port number. As we know we are
	 * passing a number already, we know this
	 * value will not be really used by the C
	 * library.
	 */
	hints.ai_socktype = SOCK_STREAM;
	errorNumber = getaddrinfo(purple_dnsquery_get_host(query_data), servname, &hints, &res);
	if (errorNumber == 0) {
		success = TRUE;
	} else {
		/*
		 if (show_debug)
			printf("dns[%d] Error: getaddrinfo returned %d\n", getpid(), rc);
		 dns_params.hostname[0] = '\0';
		 */
		success = FALSE;
	}
	
	[self performSelectorOnMainThread:@selector(lookupComplete:) withObject:(success ? [NSValue valueWithPointer:res] : nil) waitUntilDone:NO];
	[pool release];
}

- (void)lookupComplete:(NSValue *)resValue
{
	if (cancel) {
		//Cancelled, so take no action now that the lookup is complete, but we must cleanup
        struct addrinfo *res = [resValue pointerValue];
        if(res != NULL)
            freeaddrinfo(res);

	} else if (resValue) {
		//Success! Build a list of our results and pass it to the resolved callback
		AILog(@"DNS resolve complete for %s:%d",purple_dnsquery_get_host(query_data),purple_dnsquery_get_port(query_data));
		struct addrinfo *res, *tmp;
		GSList *returnData = NULL;

		res = [resValue pointerValue];
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
		
		resolved_cb(query_data, returnData);

	} else {
		//Failure :( Send an error message to the failed callback
		char message[1024];
		
		g_snprintf(message, sizeof(message), _("Error resolving %s:\n%s"),
				   purple_dnsquery_get_host(query_data), gai_strerror(errorNumber));
		failed_cb(query_data, message);
	}

	//Release our retain in init...
	[self autorelease];

	if (query_data) {
		//Can happen if we were cancelled
		[threads removeObjectForKey:[NSValue valueWithPointer:query_data]];
	}
}

- (void)cancel
{
	//Can't stop an existing thread, so let it just die gracefully when it is done
	cancel = TRUE;
	
	//To avoid collisions and the like
	[threads removeObjectForKey:[NSValue valueWithPointer:query_data]];
	query_data = NULL;
}

@end

gboolean adiumPurpleDnsRequestResolve(PurpleDnsQueryData *query_data, PurpleDnsQueryResolvedCallback resolved_cb, PurpleDnsQueryFailedCallback failed_cb)
{
	[[[adiumPurpleDnsRequest alloc] initWithData:query_data resolvedCB:resolved_cb failedCB:failed_cb] autorelease];
	return TRUE;
}

void adiumPurpleDnsRequestDestroy(PurpleDnsQueryData *query_data)
{
	[[adiumPurpleDnsRequest lookupRequestForData:query_data] cancel];
}

static PurpleDnsQueryUiOps adiumPurpleDnsRequestOps = {
	adiumPurpleDnsRequestResolve,
	adiumPurpleDnsRequestDestroy
};

PurpleDnsQueryUiOps *adium_purple_dns_request_get_ui_ops(void)
{
	return &adiumPurpleDnsRequestOps;
}
