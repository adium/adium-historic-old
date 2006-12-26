#ifdef __LITTLE_ENDIAN__
	#define INTEL_BUILD
#else
	#undef INTEL_BUILD
#endif

//More changes are at bottom of the file
#ifndef GOBJECT_COMPILATION
	#define GOBJECT_COMPILATION
#endif

#ifndef G_DISABLE_DEPRECATED
	#define G_DISABLE_DEPRECATED
#endif

#define GETTEXT_PACKAGE gettext
#define GLIB_LOCALE_DIR "/usr/local/share/locale"
#define LIBDIR "/usr/local/lib"

/* Define to 1 if your processor stores words with the most significant byte
first (like Motorola and SPARC, unlike Intel and VAX). */
//If compiling for 10.4, we're little endian since we are Intel
#ifdef INTEL_BUILD
	#undef WORDS_BIGENDIAN
#else
	#define WORDS_BIGENDIAN 1
#endif

/* Mac OS X 10.2.x did not have poll() */
/* Define to 1 if you have the `poll' function. */
//#define HAVE_POLL 1

/* alpha atomic implementation */
/* #undef G_ATOMIC_ALPHA */

/* ia64 atomic implementation */
/* #undef G_ATOMIC_IA64 */

#ifdef INTEL_BUILD
	/* i486 atomic implementation */
	#define G_ATOMIC_I486 1
#else
	/* powerpc atomic implementation */
	#define G_ATOMIC_POWERPC 1
#endif

/* sparcv9 atomic implementation */
/* #undef G_ATOMIC_SPARCV9 */

/* x86_64 atomic implementation */
/* #undef G_ATOMIC_X86_64 */


/* config.h.  Generated by configure.  */
/* config.h.in.  Generated from configure.in by autoheader.  */

/* Define to one of `_getb67', `GETB67', `getb67' for Cray-2 and Cray-YMP
   systems. This function is required for `alloca.c' support on those systems.
   */
/* #undef CRAY_STACKSEG_END */

/* Define to 1 if using `alloca.c'. */
/* #undef C_ALLOCA */

/* Whether to disable memory pools */
/* #undef DISABLE_MEM_POOLS */

/* Whether to enable GC friendliness */
/* #undef ENABLE_GC_FRIENDLY */

/* always defined to indicate that i18n is enabled */
#define ENABLE_NLS 1

/* Define the gettext package to be used */
#ifndef GETTEXT_PACKAGE
#define GETTEXT_PACKAGE "glib20"
#endif

/* Define to the GLIB binary age */
#define GLIB_BINARY_AGE 806

/* Byte contents of gmutex */
#ifdef INTEL_BUILD
	#define GLIB_BYTE_CONTENTS_GMUTEX -89,-85,-86,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
#else
	#define GLIB_BYTE_CONTENTS_GMUTEX 50,-86,-85,-89,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
#endif

/* Define to the GLIB interface age */
#define GLIB_INTERFACE_AGE 6

/* Define the location where the catalogs will be installed */
#define GLIB_LOCALE_DIR "/usr/local/share/locale"

/* Define to the GLIB major version */
#define GLIB_MAJOR_VERSION 2

/* Define to the GLIB micro version */
#define GLIB_MICRO_VERSION 6

/* Define to the GLIB minor version */
#define GLIB_MINOR_VERSION 8

/* The size of gmutex, as computed by sizeof. */
#define GLIB_SIZEOF_GMUTEX 44

/* The size of system_thread, as computed by sizeof. */
#define GLIB_SIZEOF_SYSTEM_THREAD 4

/* Whether glib was compiled with debugging enabled */
#define G_COMPILED_WITH_DEBUGGING "minimum"

/* Have inline keyword */
#define G_HAVE_INLINE 1

/* Have __inline keyword */
#define G_HAVE___INLINE 1

/* Have __inline__ keyword */
#define G_HAVE___INLINE__ 1

/* Source file containing theread implementation */
#define G_THREAD_SOURCE "gthread-posix.c"

/* A 'va_copy' style function */
#define G_VA_COPY va_copy

/* 'va_lists' cannot be copies as values */
/* #undef G_VA_COPY_AS_ARRAY */

/* Define to 1 if you have `alloca', as a function or macro. */
#define HAVE_ALLOCA 1

/* Define to 1 if you have <alloca.h> and it should be used (not on Ultrix).
   */
#define HAVE_ALLOCA_H 1

/* Define to 1 if you have the `atexit' function. */
#define HAVE_ATEXIT 1

/* Define to 1 if you have the `bind_textdomain_codeset' function. */
#define HAVE_BIND_TEXTDOMAIN_CODESET 1

/* Define if you have a version of the snprintf function with semantics as
   specified by the ISO C99 standard. */
#define HAVE_C99_SNPRINTF 1

/* Define if you have a version of the vsnprintf function with semantics as
   specified by the ISO C99 standard. */
#define HAVE_C99_VSNPRINTF 1

/* Have nl_langinfo (CODESET) */
#define HAVE_CODESET 1

/* Define to 1 if you have the <crt_externs.h> header file. */
#define HAVE_CRT_EXTERNS_H 1

/* Define to 1 if you have the `dcgettext' function. */
#define HAVE_DCGETTEXT 1

/* Define to 1 if you have the <dirent.h> header file. */
#define HAVE_DIRENT_H 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you don't have `vprintf' but do have `_doprnt.' */
/* #undef HAVE_DOPRNT */

/* Define to 1 if you have the <float.h> header file. */
#define HAVE_FLOAT_H 1

/* Define to 1 if you have the `getcwd' function. */
#define HAVE_GETCWD 1

/* Define to 1 if you have the `getc_unlocked' function. */
#define HAVE_GETC_UNLOCKED 1

#ifdef INTEL_BUILD
	#define HAVE_GETPAGESIZE 1
#endif

/* Define if the GNU gettext() function is already present or preinstalled. */
#define HAVE_GETTEXT 1

/* define to use system printf */
#define HAVE_GOOD_PRINTF 1

/* define to support printing 64-bit integers with format I64 */
/* #undef HAVE_INT64_AND_I64 */

/* Define if you have the 'intmax_t' type in <stdint.h> or <inttypes.h>. */
#define HAVE_INTMAX_T 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define if <inttypes.h> exists, doesn't clash with <sys/types.h>, and
   declares uintmax_t. */
#define HAVE_INTTYPES_H_WITH_UINTMAX 1

/* Define if you have <langinfo.h> and nl_langinfo(CODESET). */
#define HAVE_LANGINFO_CODESET 1

/* Define to 1 if you have the <langinfo.h> header file. */
#define HAVE_LANGINFO_H 1

/* Define if your <locale.h> file defines LC_MESSAGES. */
#define HAVE_LC_MESSAGES 1

/* Define to 1 if you have the <limits.h> header file. */
#define HAVE_LIMITS_H 1

/* Define to 1 if you have the <locale.h> header file. */
#define HAVE_LOCALE_H 1

/* Define to 1 if you have the `localtime_r' function. */
#define HAVE_LOCALTIME_R 1

/* Define if you have the 'long double' type. */
#define HAVE_LONG_DOUBLE 1

/* Define if you have the 'long long' type. */
#define HAVE_LONG_LONG 1

/* define if system printf can print long long */
#define HAVE_LONG_LONG_FORMAT 1

/* Define to 1 if you have the `lstat' function. */
#define HAVE_LSTAT 1

/* Define to 1 if you have the `memmove' function. */
#define HAVE_MEMMOVE 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `mkstemp' function. */
#define HAVE_MKSTEMP 1

#ifdef INTEL_BUILD
	#define HAVE_MMAP 1
#endif

/* Define to 1 if you have the `nanosleep' function. */
#define HAVE_NANOSLEEP 1

/* Define to 1 if you have the `nl_langinfo' function. */
#define HAVE_NL_LANGINFO 1

/* Have non-POSIX function getpwuid_r */
/* #undef HAVE_NONPOSIX_GETPWUID_R */

/* Define to 1 if you have the `on_exit' function. */
/* #undef HAVE_ON_EXIT */

/* Have POSIX function getpwuid_r */
#define HAVE_POSIX_GETPWUID_R 1

/* Have function pthread_attr_setstacksize */
#define HAVE_PTHREAD_ATTR_SETSTACKSIZE 1

/* Define to 1 if the system has the type `ptrdiff_t'. */
#define HAVE_PTRDIFF_T 1

/* Define to 1 if you have the <pwd.h> header file. */
#define HAVE_PWD_H 1

/* Define to 1 if you have the `readlink' function. */
#define HAVE_READLINK 1

/* Define to 1 if you have the <sched.h> header file. */
#define HAVE_SCHED_H 1

/* Define to 1 if you have the `setenv' function. */
#define HAVE_SETENV 1

/* Define to 1 if you have the `setlocale' function. */
#define HAVE_SETLOCALE 1

/* Define to 1 if you have the `snprintf' function. */
#define HAVE_SNPRINTF 1

/* Define to 1 if you have the <stddef.h> header file. */
#define HAVE_STDDEF_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define if <stdint.h> exists, doesn't clash with <sys/types.h>, and declares
   uintmax_t. */
#define HAVE_STDINT_H_WITH_UINTMAX 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `stpcpy' function. */
#define HAVE_STPCPY 1

/* Define to 1 if you have the `strcasecmp' function. */
#define HAVE_STRCASECMP 1

/* Define to 1 if you have the `strerror' function. */
#ifdef INTEL_BUILD
	#define HAVE_STRERROR 1
#endif

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Have functions strlcpy and strlcat */
#define HAVE_STRLCPY 1

/* Define to 1 if you have the `strncasecmp' function. */
#define HAVE_STRNCASECMP 1

/* Define to 1 if you have the `strsignal' function. */
#define HAVE_STRSIGNAL 1

/* Define to 1 if you have the `symlink' function. */
#define HAVE_SYMLINK 1

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/poll.h> header file. */
#define HAVE_SYS_POLL_H 1

/* found fd_set in sys/select.h */
#define HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/times.h> header file. */
#define HAVE_SYS_TIMES_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <sys/wait.h> header file. */
#ifdef INTEL_BUILD
	#define HAVE_SYS_WAIT_H 1
#endif

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define if your printf function family supports positional parameters as
   specified by Unix98. */
#define HAVE_UNIX98_PRINTF 1

/* Define to 1 if you have the `unsetenv' function. */
#define HAVE_UNSETENV 1

/* Define to 1 if you have the <values.h> header file. */
/* #undef HAVE_VALUES_H */

/* Define to 1 if you have the `vasprintf' function. */
#define HAVE_VASPRINTF 1

/* Define to 1 if you have the `vprintf' function. */
#define HAVE_VPRINTF 1

/* Define to 1 if you have the `vsnprintf' function. */
#define HAVE_VSNPRINTF 1

/* Define if you have the 'wchar_t' type. */
#define HAVE_WCHAR_T 1

/* Define if you have the 'wint_t' type. */
#ifdef INTEL_BUILD
	#define HAVE_WINT_T 1
#endif

/* Have a working bcopy */
/* #undef HAVE_WORKING_BCOPY */

/* Define to 1 if you have the `_NSGetEnviron' function. */
#define HAVE__NSGETENVIRON 1

/* didn't find fd_set */
/* #undef NO_FD_SET */

/* global 'sys_errlist' not found */
#define NO_SYS_ERRLIST 1

/* global 'sys_siglist' not found */
/* #undef NO_SYS_SIGLIST */

/* global 'sys_siglist' not declared */
/* #undef NO_SYS_SIGLIST_DECL */

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "http://bugzilla.gnome.org/enter_bug.cgi?product=glib"

/* Define to the full name of this package. */
#define PACKAGE_NAME "glib"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "glib 2.8.6"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "glib"

/* Define to the version of this package. */
#define PACKAGE_VERSION "2.8.6"

/* Maximum POSIX RT priority */
#define POSIX_MAX_PRIORITY sched_get_priority_max(SCHED_OTHER)

/* Minimum POSIX RT priority */
#define POSIX_MIN_PRIORITY sched_get_priority_min(SCHED_OTHER)

/* The POSIX RT yield function */
#define POSIX_YIELD_FUNC sched_yield()

/* whether realloc (NULL,) works */
#define REALLOC_0_WORKS 1

/* Define if you have correct malloc prototypes */
#define SANE_MALLOC_PROTOS 1

/* The size of a `char', as computed by sizeof. */
#define SIZEOF_CHAR 1

/* The size of a `int', as computed by sizeof. */
#define SIZEOF_INT 4

/* The size of a `long', as computed by sizeof. */
#define SIZEOF_LONG 4

/* The size of a `long long', as computed by sizeof. */
#define SIZEOF_LONG_LONG 8

/* The size of a `short', as computed by sizeof. */
#define SIZEOF_SHORT 2

/* The size of a `size_t', as computed by sizeof. */
#define SIZEOF_SIZE_T 4

/* The size of a `void *', as computed by sizeof. */
#define SIZEOF_VOID_P 4

/* The size of a `__int64', as computed by sizeof. */
#define SIZEOF___INT64 0

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at run-time.
	STACK_DIRECTION > 0 => grows toward higher addresses
	STACK_DIRECTION < 0 => grows toward lower addresses
	STACK_DIRECTION = 0 => direction of growth unknown */
/* #undef STACK_DIRECTION */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Using GNU libiconv */
#define USE_LIBICONV_GNU 1

/* Using a native implementation of iconv in a separate library */
/* #undef USE_LIBICONV_NATIVE */

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to long or long long if <inttypes.h> and <stdint.h> don't define. */
/* #undef intmax_t */

/* Define to empty if the C compiler doesn't support this keyword. */
/* #undef signed */

/* Define to `unsigned' if <sys/types.h> does not define. */
/* #undef size_t */

/* ***** ADIUM **** Begin changes to automatically generated file */

#define USE_LIBICONV_GNU 1
#ifndef EILSEQ
	#define EILSEQ ENOENT
#endif

/* Define to 1 if you have the `stpcpy' function. */
#undef HAVE_STPCPY
/* Define to 1 if you have the `strsignal' function. */
#undef HAVE_STRSIGNAL
/* Define to 1 if you have the `getc_unlocked' function. */
#undef HAVE_GETC_UNLOCKED
/* Define to 1 if you have the `nl_langinfo' function. */
#undef HAVE_NL_LANGINFO
/* Define if you have <langinfo.h> and nl_langinfo(CODESET). */
#undef HAVE_LANGINFO_CODESET
/* Have nl_langinfo (CODESET) */
#undef HAVE_CODESET

/* ***** ADIUM ***** End changes to automatically generated file */
