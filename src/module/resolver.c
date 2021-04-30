#include "resolver.h"
#include "uv.h"

void fileExistsSync(WrenVM* vm) {
  uv_fs_t req;
  int r = uv_fs_stat(NULL,&req,wrenGetSlotString(vm,1),NULL);
  // fprintf(stderr,"fileExists, %s  %d\n", wrenGetSlotString(vm,1), r);
  wrenEnsureSlots(vm, 1);
  // non zero is error and means we don't have a file
  wrenSetSlotBool(vm, 0, r == 0);
}

