/*#io
docCopyright("Steve Dekorte", 2002)
docLicense("BSD revised")
*/

#ifndef IOCFUNCTION_DEFINED
#define IOCFUNCTION_DEFINED 1

#include "IoVMApi.h"

#include "Common.h"
#include "IoObject.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ISCFUNCTION(self) \
  IoObject_hasCloneFunc_(self, (TagCloneFunc *)IoCFunction_rawClone)

#define IOCFUNCTION(func, tag) IoCFunction_newWithFunctionPointer_tag_name_(IOSTATE, (IoUserFunction *)func, tag, "?")

typedef IoObject *(IoUserFunction)(IoObject *, IoObject *, IoMessage *);
typedef IoObject IoCFunction;

typedef struct
{
    IoTag *typeTag; // pointer to tag of type excepted for self value to have as data 
    IoUserFunction *func;
    IoSymbol *uniqueName;
} IoCFunctionData;

IOVM_API IoCFunction *IoCFunction_proto(void *state);
IOVM_API void IoCFunction_protoFinish(void *state);
IOVM_API IoCFunction *IoCFunction_rawClone(IoCFunction *self);
IOVM_API IoCFunction *IoCFunction_newWithFunctionPointer_tag_name_(void *state, IoUserFunction *s, IoTag *typeTag, const char *name);

IOVM_API void IoCFunction_mark(IoCFunction *self);
IOVM_API void IoCFunction_free(IoCFunction *self);
IOVM_API void IoCFunction_print(IoCFunction *self);

IOVM_API IoObject *IoCFunction_id(IoCFunction *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoCFunction_uniqueName(IoCFunction *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoCFunction_typeName(IoCFunction *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoCFunction_equals(IoCFunction *self, IoObject *locals, IoMessage *m);
IOVM_API IoObject *IoCFunction_activate(IoCFunction *self, IoObject *target, IoObject *locals, IoMessage *m, IoObject *slotContext);

IOVM_API IoObject *IoFunction_performOn(IoCFunction *self, IoObject *locals, IoMessage *m);

#ifdef __cplusplus
}
#endif
#endif

