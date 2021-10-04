/***
 * TODO: something like intermediate level of compartment switching or ...
 ***/

#include "../../include/common.h"
#include "../include/utils.h"
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#if !defined(__CHERI_CAPABILITY_WIDTH__) || defined(__CHERI_PURE_CAPABILITY__)
#error "This example only works on CHERI hybrid mode"
#endif

// Simple function with some data which will be part of the compartment
int compartment_simple_fun();
// int compartment_simple_fun(int a, int b);
extern int switch_compartment(void *stack, size_t size);
// extern int switch_compartment(void * stack, size_t size);

int main()
{
	void *simple_block = malloc(5000);
	size_t compartment_size = 2000;
	// pp_cap(read_ddc());
	switch_compartment(simple_block, compartment_size);
	// pp_cap(read_ddc());
	return 0;
}

int compartment_simple_fun()
{
	void *__capability ddc_cap = cheri_ddc_get();
	assert(cheri_length_get(ddc_cap) == 2000);
	return 0;
}