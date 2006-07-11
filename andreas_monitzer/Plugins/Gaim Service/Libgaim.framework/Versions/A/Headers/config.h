//Needed to do proper VERSION_MIN_REQUIRED checking
#include <AvailabilityMacros.h>

/* Version number of package */
#define VERSION "2.0.0"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libgaim 2.0.0"

/* OTR version */
#define GAIM_OTR_VERSION "3.0.0"

/* MEANWHILE plugin */
#define MW_PLUGIN_DEFAULT_ACTIVE_MSG ""
#define MW_PLUGIN_DEFAULT_AWAY_MSG "Away"
#define MW_PLUGIN_DEFAULT_BUSY_MSG "Busy"
#define MW_CLIENT_TYPE_ID mwLogin_MEANWHILE

/* OS X has OPEN_SSL */
#define HAVE_OPENSSL TRUE

/* OS X 10.2.x does not have poll() */
/* Define to 1 if you have the `poll' function. */
/* #define HAVE_POLL 1 */

/* Define to the version of this package. */
#define PACKAGE_VERSION VERSION

/* Name of package */
#define PACKAGE "libgaim"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "gaim-devel@lists.sourceforge.net"

/* Define to the full name of this package. */
#define PACKAGE_NAME PACKAGE

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME PACKAGE

/* Define if kerberos should be used in Zephyr. */
#define ZEPHYR_USES_KERBEROS

/* For Zephyr */
#define CONFDIR "~"

#define SYSCONFDIR "~/Library/Application Support/Adium 2.0/"

/* Define to 1 if your processor stores words with the most significant byte
first (like Motorola and SPARC, unlike Intel and VAX). */
//If compiling for 10.4, we're little endian since we are Intel. < 10.4, we are Mac. 
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_4
	#define WORDS_BIGENDIAN 1

	/* socklen_t size */
	#ifndef socklen_t
		#define socklen_t int
		#define SOCKLEN_T
	#endif
#endif

/* Define if plugins are enabled. */
//#define GAIM_PLUGINS

/* configure arguments */
#define CONFIG_ARGS "'--disable-perl' '--enable-debug'"

/* Define if debugging is enabled. */
#define DEBUG 1

/* Define if mono enabled. */
/* #undef ENABLE_MONO */

/* always defined to indicate that i18n is enabled */
#define ENABLE_NLS 1

/* Define to make assertions fatal (useful for debugging). */
/* #define GAIM_FATAL_ASSERTS 1 */

/* Define if plugins are enabled. */
//#define GAIM_PLUGINS 1

/* Define if you have the external 'altzone' variable. */
/* #undef HAVE_ALTZONE */

/* Define to 1 if you have the <arpa/nameser_compat.h> header file. */
#define HAVE_ARPA_NAMESER_COMPAT_H 1

/* Define to 1 if you have the `atexit' function. */
#define HAVE_ATEXIT 1

/* Define to 1 if you have the `bind_textdomain_codeset' function. */
#define HAVE_BIND_TEXTDOMAIN_CODESET 1

/* Define to 1 if you have the `connect' function. */
#define HAVE_CONNECT 1

/* Define to 1 if Cyrus SASL is present */
/* #undef HAVE_CYRUS_SASL */

/* Define if you have the external 'daylight' variable. */
#define HAVE_DAYLIGHT 1

/* Define if we are re using DBUS. */
/* #undef HAVE_DBUS */

/* Define to 1 if you have the `dcgettext' function. */
#define HAVE_DCGETTEXT 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* whether or not we have dot */
/* #undef HAVE_DOT */

/* whether or not we have doxygen */
/* #undef HAVE_DOXYGEN */

/* Define if we're using evolution addressbook. */
/* #undef HAVE_EVOLUTION_ADDRESSBOOK */

/* Define to 1 if you have the <EXTERN.h> header file. */
/* #undef HAVE_EXTERN_H */

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the getaddrinfo function. */
#define HAVE_GETADDRINFO 1

/* Define to 1 if you have the `gethostid' function. */
#define HAVE_GETHOSTID 1

/* Define to 1 if you have the `getopt_long' function. */
#define HAVE_GETOPT_LONG 1

/* Define if the GNU gettext() function is already present or preinstalled. */
#define HAVE_GETTEXT 1

/* Define if you have GnuTLS */
#define HAVE_GNUTLS 1

/* Define to 1 if you have the <gnutls/gnutls.h> header file. */
#define HAVE_GNUTLS_GNUTLS_H 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define if we have IOKit */
#define HAVE_IOKIT 1

/* Define to 1 if you have the `krb_get_err_text' function. */
/* #undef HAVE_KRB_GET_ERR_TEXT */

/* Define to 1 if you have the `krb_get_lrealm' function. */
/* #undef HAVE_KRB_GET_LREALM */

/* Define to 1 if you have the `krb_log' function. */
/* #undef HAVE_KRB_LOG */

/* Define to 1 if you have the `krb_rd_req' function. */
/* #undef HAVE_KRB_RD_REQ */

/* Define to 1 if you have the `krb_set_key' function. */
/* #undef HAVE_KRB_SET_KEY */

/* Define if your <locale.h> file defines LC_MESSAGES. */
#define HAVE_LC_MESSAGES 1

/* Define to 1 if you have libgadu. */
/* #undef HAVE_LIBGADU */

/* Define to 1 if you have the `nsl' library (-lnsl). */
/* #undef HAVE_LIBNSL */

/* Define to 1 if you have the `resolv' library (-lresolv). */
#define HAVE_LIBRESOLV 1

/* Define to 1 if you have the `socket' library (-lsocket). */
/* #undef HAVE_LIBSOCKET */

/* Use libxml2 for xml parsing */
// #define HAVE_LIBXML 1

/* Define to 1 if you have the <locale.h> header file. */
#define HAVE_LOCALE_H 1

/* Define to 1 if you have the `lrand48' function. */
#define HAVE_LRAND48 1

/* Define to 1 if you have the <malloc.h> header file. */
/* #undef HAVE_MALLOC_H */

/* Define to 1 if you have the `memcpy' function. */
#define HAVE_MEMCPY 1

/* Define to 1 if you have the `memmove' function. */
#define HAVE_MEMMOVE 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `mono_jit_init' function. */
/* #undef HAVE_MONO_JIT_INIT */

/* Define to 1 if you have the <mono/jit/jit.h> header file. */
/* #undef HAVE_MONO_JIT_JIT_H */

/* Define to 1 if you have the <mono/metadata/object.h> header file. */
/* #undef HAVE_MONO_METADATA_OBJECT_H */

/* Define to 1 if you have the <nspr.h> header file. */
/* #undef HAVE_NSPR_H */

/* Define if you have Mozilla NSS */
/* #undef HAVE_NSS */

/* Define to 1 if you have the <nss.h> header file. */
/* #undef HAVE_NSS_H */

/* Define to 1 if you have the <paths.h> header file. */
#define HAVE_PATHS_H 1

/* Compile with support for perl */
/* #undef HAVE_PERL */

/* Define to 1 if you have the `Perl_eval_pv' function. */
/* #undef HAVE_PERL_EVAL_PV */

/* Define to 1 if you have the <perl.h> header file. */
/* #undef HAVE_PERL_H */

/* Define to 1 if you have the `perl_run' function. */
/* #undef HAVE_PERL_RUN */

/* Define to 1 if you have the <prio.h> header file. */
/* #undef HAVE_PRIO_H */

/* Define to 1 if you have the `random' function. */
#define HAVE_RANDOM 1

/* Define to 1 if you have the <regex.h> header file. */
#define HAVE_REGEX_H 1

/* Define to 1 if you have the `setlocale' function. */
#define HAVE_SETLOCALE 1

/* Define to 1 if you have the <sgtty.h> header file. */
#define HAVE_SGTTY_H 1

/* Define to 1 if you have the <signal.h> header file. */
#define HAVE_SIGNAL_H 1

/* Define if we have silcmime.h */
/* #undef HAVE_SILCMIME_H */

/* Define to 1 if you have the <smime.h> header file. */
/* #undef HAVE_SMIME_H */

/* Define to 1 if you have the `snprintf' function. */
#define HAVE_SNPRINTF 1

/* Define if you have SSL */
#define HAVE_SSL 1

/* Define to 1 if you have the <ssl.h> header file. */
/* #undef HAVE_SSL_H */

/* Define if we're using libstartup-notification. */
/* #undef HAVE_STARTUP_NOTIFICATION */

/* Define to 1 if you have the <stdarg.h> header file. */
#define HAVE_STDARG_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strchr' function. */
#define HAVE_STRCHR 1

/* Define to 1 if you have the `strdup' function. */
#define HAVE_STRDUP 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the `strftime' function. */
#define HAVE_STRFTIME 1

/* Define to 1 if you have a strftime() that supports the %z format string. */
#define HAVE_STRFTIME_Z_FORMAT 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strstr' function. */
#define HAVE_STRSTR 1

/* Define to 1 if `tm_zone' is member of `struct tm'. */
#define HAVE_STRUCT_TM_TM_ZONE 1

/* Define to 1 if you have the <sys/cdefs.h> header file. */
#define HAVE_SYS_CDEFS_H 1

/* Define to 1 if you have the <sys/file.h> header file. */
#define HAVE_SYS_FILE_H 1

/* Define to 1 if you have the <sys/filio.h> header file. */
#define HAVE_SYS_FILIO_H 1

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/msgbuf.h> header file. */
#define HAVE_SYS_MSGBUF_H 1

/* Define to 1 if you have the <sys/select.h> header file. */
#define HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <sys/uio.h> header file. */
#define HAVE_SYS_UIO_H 1

/* Define to 1 if you have the <sys/utsname.h> header file. */
#define HAVE_SYS_UTSNAME_H 1

/* Define to 1 if you have the <sys/wait.h> header file. */
#define HAVE_SYS_WAIT_H 1

/* Compile with support for the Tcl toolkit */
#define HAVE_TCL 1

/* Define to 1 if you have the <termios.h> header file. */
#define HAVE_TERMIOS_H 1

/* Define if you have the external 'timezone' variable. */
#define HAVE_TIMEZONE 1

/* Compile with support for the Tk toolkit */
#define HAVE_TK 1

/* tm_gmtoff is available. */
#define HAVE_TM_GMTOFF 1

/* Define to 1 if your `struct tm' has `tm_zone'. Deprecated, use
   `HAVE_STRUCT_TM_TM_ZONE' instead. */
#define HAVE_TM_ZONE 1

/* Define to 1 if you don't have `tm_zone' but do have the external array
   `tzname'. */
/* #undef HAVE_TZNAME */

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the `vprintf' function. */
#define HAVE_VPRINTF 1

/* Define to 1 if you have the <X11/SM/SMlib.h> header file. */
#define HAVE_X11_SM_SMLIB_H 1

/* Define if external libzephyr should be used. */
/* #undef LIBZEPHYR_EXT */

/* Define if old perl is installed. */
/* #undef OLD_PERL */

/* Define as the return type of signal handlers (`int' or `void'). */
#define RETSIGTYPE void

/* Loads static protocol plugin module initialization functions. */
#define STATIC_PROTO_INIT static void static_proto_init() {  }

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* Use GStreamer for making sounds */
/* #undef USE_GSTREAMER */

/* do we have gtkspell? */
/* #undef USE_GTKSPELL */

/* Define if we're using XScreenSaver. */
// #define USE_SCREENSAVER 1

/* Define if we're using X Session Management. */
// #define USE_SM 1

/* Define to 1 if the X Window System is missing or not being used. */
/* #undef X_DISPLAY_MISSING */

/* Size of an int32. */
#define ZEPHYR_INT32 long

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* socklen_t size */
/* #undef socklen_t */
