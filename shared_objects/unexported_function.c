/**
 * An example showing how functions put into different shared objects are in different compartments
 * based on the function pointers that can be observed in the PCC of the current function. The 
 * range represented by the PCC is scanned twice, once inside of the function and once outside to
 * show that the two differ. 
 */

#include <stdio.h>
#include <dlfcn.h>
#include "include/unexported_function.h"
#include "include/find_sentries.h"

__attribute__ ((visibility ("hidden")))
void do_work() {
	printf("Doing work\n");
}

int test() {

	

	printf("Finding do_work using dlsym (lib4):\nptr: "); inspect_pointer(dlsym(NULL, "do_work"));
	printf("Obtaining a direct pointer to it: \nptr: "); inspect_pointer(&do_work);
	printf("test ptr just to keep it in the pcc:\n ptr: %p\n", &test);
	printf(" ------- scanning pcc for sealed pointers --------\n");
	scan_range(cheri_getpcc());

	do_work();
	return 99;
}
