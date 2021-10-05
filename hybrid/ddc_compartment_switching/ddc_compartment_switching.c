/***
 * This example shows an intermediate level of compartment creation.
 * It allocates a block of memory (5000 bytes) but only the first
 * 2000 are accessible by `compartment_simple_fun`.
 *
 * This program does not rise any exception because we verify we can
 * read an `int32_t` allocated in those first 2000 bytes.
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

// Simple function accessing the compartment
int compartment_simple_fun();
// The function connected to the assembly trampoline
extern int switch_compartment(void *stack, size_t size);

int main()
{
	int32_t *simple_block = malloc(5000);
	size_t compartment_size = 2000;
	simple_block[483] = 800;
	switch_compartment(simple_block, compartment_size);
	return 0;
}

int compartment_simple_fun()
{
	int32_t *__capability ddc_cap = cheri_ddc_get();
	// This function can read only 2000 bytes, i.e. `compartment_size`
	assert(cheri_tag_get(ddc_cap) && cheri_length_get(ddc_cap) == 2000);
	assert(ddc_cap[483] == 800);
	return 0;
}