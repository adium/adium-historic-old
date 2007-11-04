/*
 * CDSA SSL-plugin for purple
 *
 * Copyright (c) 2007 Andreas Monitzer <andy@monitzer.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <libpurple/internal.h>
#include <libpurple/debug.h>
#include <libpurple/plugin.h>
#include <libpurple/sslconn.h>
#include <libpurple/version.h>
#include <libpurple/signals.h>

#define SSL_CDSA_PLUGIN_ID "ssl-cdsa"

//#define HAVE_CDSA
//#warning Move this define to the xcode settinge BEFORE committing

#ifdef HAVE_CDSA

#include <Security/Security.h>
#include <unistd.h>

typedef struct
{
	SSLContextRef	ssl_ctx;
	guint	handshake_handler;
} PurpleSslCDSAData;

#define PURPLE_SSL_CDSA_DATA(gsc) ((PurpleSslCDSAData *)gsc->private_data)

/*
 * query_cert_chain - callback for letting the user review the certificate before accepting it
 *
 * err: one of the following:
 *  errSSLUnknownRootCert—The peer has a valid certificate chain, but the root of the chain is not a known anchor certificate.
 *  errSSLNoRootCert—The peer's certificate chain was not verifiable to a root certificate.
 *  errSSLCertExpired—The peer's certificate chain has one or more expired certificates.
 *  errSSLXCertChainInvalid—The peer has an invalid certificate chain; for example, signature verification within the chain failed, or no certificates were found.
 * hostname: The name of the host to be verified (for display purposes)
 * certs: an array of values of type SecCertificateRef representing the peer certificate and the certificate chain used to validate it. The certificate at index 0 of the returned array is the peer certificate; the root certificate (or the closest certificate to it) is at the end of the returned array.
 * accept_cert: the callback to be called when the user chooses to trust this certificate chain
 * reject_cert: the callback to be called when the user does not trust this certificate chain
 * userdata: opaque pointer which has to be passed to the callbacks
 */
typedef
void (*query_cert_chain)(OSStatus err, const char *hostname, CFArrayRef certs, void (*accept_cert)(void *userdata), void (*reject_cert)(void *userdata), void *userdata);

static query_cert_chain *certificate_ui_cb = NULL;

/*
 * ssl_cdsa_init
 */
static gboolean
ssl_cdsa_init(void)
{
	return (TRUE);
}

/*
 * ssl_cdsa_uninit
 */
static void
ssl_cdsa_uninit(void)
{
}

struct query_cert_userdata {
	CFArrayRef certs;
	char *hostname;
	PurpleSslConnection *gsc;
	PurpleInputCondition cond;
};

static void
ssl_cdsa_handshake_cb(gpointer data, gint source, PurpleInputCondition cond);

static void query_cert_ok(void *userdata) {
	OSStatus err;
	struct query_cert_userdata *ud = (struct query_cert_userdata*)userdata;
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(ud->gsc);
	
	CFRelease(ud->certs);
	free(ud->hostname);
	
	err = SSLSetEnableCertVerify(cdsa_data->ssl_ctx, false);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetEnableCertVerify failed\n");
		
		if (ud->gsc->error_cb != NULL)
			ud->gsc->error_cb(ud->gsc, PURPLE_SSL_CERTIFICATE_INVALID,
							  ud->gsc->connect_cb_data);
		
		purple_ssl_close(ud->gsc);
	}
    else
		ssl_cdsa_handshake_cb(ud->gsc, ud->gsc->fd, ud->cond); // try again with cert checking off
	
	free(ud);
}

static void query_cert_cancel(void *userdata) {
	struct query_cert_userdata *ud = (struct query_cert_userdata*)userdata;
	
	CFRelease(ud->certs);
	free(ud->hostname);
	
	if (ud->gsc->error_cb != NULL)
		ud->gsc->error_cb(ud->gsc, PURPLE_SSL_CERTIFICATE_INVALID,
						  ud->gsc->connect_cb_data);
	
	purple_ssl_close(ud->gsc);
	
	free(ud);
}

/*
 * ssl_cdsa_handshake_cb
 */
static void
ssl_cdsa_handshake_cb(gpointer data, gint source, PurpleInputCondition cond)
{
	PurpleSslConnection *gsc = (PurpleSslConnection *)data;
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
    OSStatus err;
    
	purple_debug_info("cdsa", "Connecting\n");
    
	/*
	 * do the negotiation that sets up the SSL connection between
	 * here and there.
	 */
    err = SSLHandshake(cdsa_data->ssl_ctx);
    if(err != noErr) {
        if(err == errSSLWouldBlock)
            return;
		if(certificate_ui_cb && (err == errSSLUnknownRootCert || err == errSSLNoRootCert || err == errSSLCertExpired || err == errSSLXCertChainInvalid)) {
			struct query_cert_userdata *userdata = (struct query_cert_userdata*)malloc(sizeof(struct query_cert_userdata));
			size_t hostnamelen = 0;
			
			SSLGetPeerDomainNameLength(cdsa_data->ssl_ctx, &hostnamelen);
			userdata->hostname = (char*)malloc(hostnamelen+1);
			SSLGetPeerDomainName(cdsa_data->ssl_ctx, userdata->hostname, &hostnamelen);
			userdata->hostname[hostnamelen] = '\0'; // just make sure it's zero-terminated
			
			SSLCopyPeerCertificates(cdsa_data->ssl_ctx, &userdata->certs);
			
			(*certificate_ui_cb)(err, userdata->hostname, userdata->certs, query_cert_ok, query_cert_cancel, userdata);
		} else {
			fprintf(stderr,"cdsa: SSLHandshake failed with error %d\n",(int)err);
			purple_debug_error("cdsa", "SSLHandshake failed with error %d\n",(int)err);
			if (gsc->error_cb != NULL)
				gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
							  gsc->connect_cb_data);
			
			purple_ssl_close(gsc);
		}
		return;
    }
	    
	purple_input_remove(cdsa_data->handshake_handler);
	cdsa_data->handshake_handler = 0;
    
	purple_debug_info("cdsa", "SSL_connect complete\n");
    
	/* SSL connected now */
	gsc->connect_cb(gsc->connect_cb_data, gsc, cond);
}

/*
 * R/W. Called out from SSL.
 */
static OSStatus SocketRead(
                    SSLConnectionRef   connection,
                    void         *data,       /* owned by 
                                               * caller, data
                                               * RETURNED */
                    size_t         *dataLength)  /* IN/OUT */ 
                    {
    UInt32      bytesToGo = *dataLength;
    UInt32       initLen = bytesToGo;
    UInt8      *currData = (UInt8 *)data;
    int        sock = (int)connection;
    OSStatus    rtn = noErr;
    UInt32      bytesRead;
    int        rrtn;
    
    *dataLength = 0;
    
    for(;;) {
        bytesRead = 0;
        rrtn = read(sock, currData, bytesToGo);
        if (rrtn <= 0) {
            /* this is guesswork... */
            int theErr = errno;
            switch(theErr) {
                case ENOENT:
                    /* connection closed */
                    rtn = errSSLClosedGraceful; 
                    break;
                case ECONNRESET:
                    rtn = errSSLClosedAbort;
                    break;
                case EAGAIN:
                    rtn = errSSLWouldBlock;
                    break;
                default:
                    fprintf(stderr,"SocketRead: read(%d) error %d\n", 
                             (int)bytesToGo, theErr);
                    rtn = errSSLFatalAlert;
                    break;
            }
            break;
        }
        else {
            bytesRead = rrtn;
        }
        bytesToGo -= bytesRead;
        currData  += bytesRead;
        
        if(bytesToGo == 0) {
            /* filled buffer with incoming data, done */
            break;
        }
    }
    *dataLength = initLen - bytesToGo;
    if(rtn != noErr && rtn != errSSLWouldBlock)
        fprintf(stderr,"SocketRead err = %d\n", (int)rtn);
    
    return rtn;
}

static OSStatus SocketWrite(
                     SSLConnectionRef   connection,
                     const void       *data, 
                     size_t         *dataLength)  /* IN/OUT */ 
                     {
    UInt32    bytesSent = 0;
    int      sock = (int)connection;
    int     length;
    UInt32    dataLen = *dataLength;
    const UInt8 *dataPtr = (UInt8 *)data;
    OSStatus  ortn;

/*
    if(*dataLength > 1) {
        UInt32 i;
        UInt32 outLen;
        UInt32 thisMove;
        
        outLen = 0;
        for(i=0; i<dataLen; i++) {
            thisMove = 1;
            ortn = SocketWrite(connection, dataPtr, &thisMove);
            outLen += thisMove;
            dataPtr++;  
            if(ortn) {
                return ortn;
            }
        }
        return noErr;
    }
*/
    *dataLength = 0;
    
    do {
        length = write(sock, 
                       (char*)dataPtr + bytesSent, 
                       dataLen - bytesSent);
    } while ((length > 0) && 
             ( (bytesSent += length) < dataLen) );
    
    if(length <= 0) {
        if(errno == EAGAIN) {
            ortn = errSSLWouldBlock;
        }
        else {
            ortn = errSSLFatalAlert;
        }
    }
    else {
        ortn = noErr;
    }
    *dataLength = bytesSent;
    return ortn;
}

/*
 * ssl_cdsa_connect
 *
 * given a socket, put an cdsa connection around it.
 */
static void
ssl_cdsa_connect(PurpleSslConnection *gsc)
{
	PurpleSslCDSAData *cdsa_data;
    OSStatus err;

	/*
	 * allocate some memory to store variables for the cdsa connection.
	 * the memory comes zero'd from g_new0 so we don't need to null the
	 * pointers held in this struct.
	 */
	cdsa_data = g_new0(PurpleSslCDSAData, 1);
	gsc->private_data = cdsa_data;

	/*
	 * allocate a new SSLContextRef object
	 */
    err = SSLNewContext(false,&cdsa_data->ssl_ctx);
	if (err != noErr) {
		purple_debug_error("cdsa", "SSLNewContext failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
				gsc->connect_cb_data);

		purple_ssl_close(gsc);
		return;
	}
    
    /*
     * Set up our callbacks for reading/writing the file descriptor
     */
    err = SSLSetIOFuncs(cdsa_data->ssl_ctx, SocketRead, SocketWrite);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetIOFuncs failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
		purple_ssl_close(gsc);
		return;
    }
    
    /*
     * Pass the connection information to the connection to be used by our callbacks
     */
    err = SSLSetConnection(cdsa_data->ssl_ctx,(SSLConnectionRef)gsc->fd);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetConnection failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
		purple_ssl_close(gsc);
		return;
    }
    
    if(gsc->host) {
        /*
         * Set the peer's domain name so CDSA can check the certificate's CN
         */
        err = SSLSetPeerDomainName(cdsa_data->ssl_ctx, gsc->host, strlen(gsc->host));
        if (err != noErr) {
            purple_debug_error("cdsa", "SSLSetPeerDomainName failed\n");
            if (gsc->error_cb != NULL)
                gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                              gsc->connect_cb_data);
            
            purple_ssl_close(gsc);
            return;
        }
    }
    
    /*
     * Disable verifying the certificate chain.
     * WARNING: This should be changed when there's a flag for that.
     */
    err = SSLSetEnableCertVerify(cdsa_data->ssl_ctx, certificate_ui_cb != NULL);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetEnableCertVerify failed\n");
        /* error is not fatal */
    }
    
    cdsa_data->handshake_handler = purple_input_add(gsc->fd, PURPLE_INPUT_READ, ssl_cdsa_handshake_cb, gsc);

    ssl_cdsa_handshake_cb(gsc, gsc->fd, PURPLE_INPUT_READ);
}

static void
ssl_cdsa_close(PurpleSslConnection *gsc)
{
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);

	if (cdsa_data == NULL)
		return;

	if (cdsa_data->handshake_handler)
		purple_input_remove(cdsa_data->handshake_handler);

	if (cdsa_data->ssl_ctx != NULL) {
        OSStatus err;
        SSLSessionState state;
        
        err = SSLGetSessionState(cdsa_data->ssl_ctx, &state);
        if(err != noErr)
            purple_debug_error("cdsa", "SSLGetSessionState failed\n");
        else if(state == kSSLConnected) {
            err = SSLClose(cdsa_data->ssl_ctx);
            if(err != noErr)
                purple_debug_error("cdsa", "SSLClose failed\n");
        }
        
        err = SSLDisposeContext(cdsa_data->ssl_ctx);
        if(err != noErr)
            purple_debug_error("cdsa", "SSLDisposeContext failed\n");
        cdsa_data->ssl_ctx = NULL;
    }

	g_free(cdsa_data);
	gsc->private_data = NULL;
}

static size_t
ssl_cdsa_read(PurpleSslConnection *gsc, void *data, size_t len)
{
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
	size_t s = 0;
    OSStatus err;

    errno = 0;
    err = SSLRead(cdsa_data->ssl_ctx, data, len, &s);
    if(err != noErr) {
        if(err == errSSLWouldBlock) {
            errno = EAGAIN;
            return -1;
        }
		purple_debug_error("cdsa", "receive failed (%d): %s\n", err, strerror(errno));
        return -1;
    }
    
    return s;
}

static size_t
ssl_cdsa_write(PurpleSslConnection *gsc, const void *data, size_t len)
{
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
	size_t s = 0;
    OSStatus err;

	if (cdsa_data != NULL) {
        err = SSLWrite(cdsa_data->ssl_ctx, data, len, &s);
        
        if(err != noErr) {
            if(err == errSSLWouldBlock) {
                errno = EAGAIN;
                return -1;
            }
            purple_debug_error("cdsa", "send failed (%d): %s\n", err, strerror(errno));
            return -1;
        }
    }
    
    return s;
}

static gboolean register_certificate_ui_cb(query_cert_chain *cb) {
	certificate_ui_cb = cb;
	
	return true;
}

static PurpleSslOps ssl_ops = {
	ssl_cdsa_init,
	ssl_cdsa_uninit,
	ssl_cdsa_connect,
	ssl_cdsa_close,
	ssl_cdsa_read,
	ssl_cdsa_write
};

#endif /* HAVE_CDSA */

static gboolean
plugin_load(PurplePlugin *plugin)
{
#ifdef HAVE_CDSA
	if (!purple_ssl_get_ops())
		purple_ssl_set_ops(&ssl_ops);
	
	purple_plugin_ipc_register(plugin,
							   "register_certificate_ui_cb",
							   PURPLE_CALLBACK(register_certificate_ui_cb),
							   purple_marshal_BOOLEAN__POINTER,
							   purple_value_new(PURPLE_TYPE_BOOLEAN),
							   1, purple_value_new(PURPLE_TYPE_POINTER));

	return (TRUE);
#else
	return (FALSE);
#endif
}

static gboolean
plugin_unload(PurplePlugin *plugin)
{
#ifdef HAVE_CDSA
	if (purple_ssl_get_ops() == &ssl_ops)
		purple_ssl_set_ops(NULL);
	
	purple_plugin_ipc_unregister_all(plugin);
#endif

	return (TRUE);
}

static PurplePluginInfo info = {
	PURPLE_PLUGIN_MAGIC,
	PURPLE_MAJOR_VERSION,
	PURPLE_MINOR_VERSION,
	PURPLE_PLUGIN_STANDARD,				/* type */
	NULL,						/* ui_requirement */
	PURPLE_PLUGIN_FLAG_INVISIBLE,			/* flags */
	NULL,						/* dependencies */
	PURPLE_PRIORITY_DEFAULT,				/* priority */

	SSL_CDSA_PLUGIN_ID,				/* id */
	N_("CDSA"),					/* name */
	"0.1",					/* version */

	N_("Provides SSL support through CDSA."),	/* description */
	N_("Provides SSL support through CDSA."),
	"CDSA",
	"http://www.opengroup.org/security/l2-cdsa.htm",						/* homepage */

	plugin_load,					/* load */
	plugin_unload,					/* unload */
	NULL,						/* destroy */

	NULL,						/* ui_info */
	NULL,						/* extra_info */
	NULL,						/* prefs_info */
	NULL						/* actions */
};

static void
init_plugin(PurplePlugin *plugin)
{
}

PURPLE_INIT_PLUGIN(ssl_cdsa, init_plugin, info)
