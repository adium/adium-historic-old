
#include "IoVMApi.h"

// Embedding callback function types

typedef void (IoStateBindingsInitCallback)(void *, void *);
typedef void (IoStatePrintCallback)(void *, size_t count, const char *);
typedef void (IoStateExceptionCallback)(void *, IoObject *);
typedef void (IoStateExitCallback)(void *, int);
typedef void (IoStateActiveCoroCallback)(void *, int);
typedef void (IoStateThreadLockCallback)(void *);
typedef void (IoStateThreadUnlockCallback)(void *);

// context

IOVM_API void IoState_callbackContext_(IoState *self, void *context);
IOVM_API void *IoState_callbackContext(IoState *self);

// bindings

IOVM_API void IoState_setBindingsInitCallback(IoState *self, IoStateBindingsInitCallback *callback);

// print

IOVM_API void IoState_print_(IoState *self, const char *format, ...);
IOVM_API void IoState_justPrint_(IoState *self, const size_t count, const char *s);
IOVM_API void IoState_justPrintln_(IoState *self);
IOVM_API void IoState_justPrintba_(IoState *self, ByteArray *ba);
IOVM_API void IoState_printCallback_(IoState *self, IoStatePrintCallback *callback);

// exceptions

IOVM_API void IoState_exceptionCallback_(IoState *self, IoStateExceptionCallback *callback);
IOVM_API void IoState_exception_(IoState *self, IoObject *e);

// exit

IOVM_API void IoState_exitCallback_(IoState *self, IoStateExitCallback *callback);
IOVM_API void IoState_exit(IoState *self, int returnCode);

// coros - called when coro count changes

IOVM_API void IoState_activeCoroCallback_(IoState *self, IoStateActiveCoroCallback *callback);
IOVM_API void IoState_schedulerUpdate(IoState *self, int count);

