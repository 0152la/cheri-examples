/* Compartment from which we call the switcher to perform inter-compartment
 * transition. The call is via a capability, to update the PCC bounds
 * appropriately to cover `switch_compartment`.
 */
.type comp_f_fn, "function"
comp_f_fn:
    // Get prior DDC of compartment we switched from
    ldr       c0, [sp]
    msr       DDC, c0

    // Get prior CLR of compartment we switched from, saved on our stack
    ldr       c0, [sp, #16]
    adr       x1, comp_f_malicious
    cvt       c1, c0, x1
    br        c1

comp_f_fn_end:

/* The function in this compartment just writes to some memory within its
 * bounds, to ensure it is properly called.
 */
.type comp_g_fn, "function"
comp_g_fn:
    mrs       c10, DDC
    mov       x11, 42
    str       x11, [x10, #4000]

    ret clr
comp_g_fn_end:

.type comp_f_malicious, "function"
comp_f_malicious:
    mov       x0, 22
    b         exit
