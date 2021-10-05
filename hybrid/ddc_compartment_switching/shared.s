// Copyright (c) 2021 The CapableVMs "CHERI Examples" Contributors.
// SPDX-License-Identifier: MIT OR Apache-2.0

.global compartment_simple_fun

.text
.balign 4
.global switch_compartment
.type switch_compartment, "function"
switch_compartment:
    // int switch_compartment(int a, int b, void * stack, size_t size)
    //
    // For the purposes of this demo, `stack + size` must be 16-byte-aligned, so
    // that it is suitable for use as a stack pointer with no additional
    // alignment logic. In addition, the range [stack, stack+size) must be
    // exactly representable as capability bounds.
    //
    // Note that, for this demo, the PCC is not restricted at all. Hybrid
    // CheriBSD targets give the PCC very wide bounds, and all 'Load'
    // permissions. In a real deployment, the PCC should be suitably restricted
    // too, but this is likely to require co-operation with the C toolchain and
    // runtime environment, since it will probably use the PCC to access literal
    // pools, globals and other data outside the function itself.
    //
    // The new stack space must be wholly enclosed by the current DDC.
    //
    // The procedure-call standard is assumed to be AAPCS64 with the Morello
    // supplement[1]. This is known as "hybrid" (as opposed to "purecap") mode.
    //
    // [1]: https://developer.arm.com/documentation/102205/latest
    //
    // Arguments are arranged as follows:
    //
    //      x0: stack   (pointer, not capability, since this is hybrid)
    //      x1: size
    //
    // The result will be returned in w0.

    // Derive a new DDC to cover the new stack.
    mrs       c10, DDC
    scvalue   c11, c10, x0
    scbndse   c11, c11, x1
    msr       DDC, c11

    // Replace the stack pointer.
    mov       x12, sp
    add       sp, x0, x1

    // Save the old DDC, stack pointer and return address on the new stack, so
    // we can restore it when we return..
    // This is the leaky part of the compartmentalisation. If strict
    // compartments are required, some other technique must be used, such as a
    // privileged switcher or sealing mechanism (e.g. using `ldpblr`).
    str       c10, [sp, #-32]!
    stp       x12, lr, [sp, #16]

    // Stack layout at this point:
    //
    //     `stack + size` -> ________________________
    //            sp + 24 -> [      old LR       ]   ^
    //            sp + 16 -> [      old SP       ]   |
    //            sp +  8 -> [ old DDC (high 64) ]   | DDC bounds
    //            sp +  0 -> [ old DDC (low 64)  ]   |
    //                                 :             :
    //            `stack` -> ________________________v
    //
    // Note that this is _not_ an AAPCS64 frame record, even though it looks a
    // bit like one. We don't touch FP here, and since it is not a capability
    // (in hybrid mode), unwinding would fail anyway.

    // Clean capabilities left in arguments.
    
    bl (clean + 8)
    bl compartment_simple_fun
    // Clean capabilities left in the return value.
    mov w0, w0
    bl (clean + 4)

    // Restore the caller's context and compartment.
    ldr       c10, [sp]
    ldp       x12, lr, [sp, #16]
    msr       DDC, c10
    mov       x10, #0
    mov       sp, x12

    ret


    // Inner helper for cleaning capabilities from registers, either side of an
    // AAPCS64 function call where some level of distrust exists between caller
    // and callee..
    //
    // Depending on the trust model, this might not be required, but the process
    // is included here for demonstration purposes. Note that if data needs to
    // be scrubbed as well as capabilities, then NEON registers also need to be
    // cleaned.
    //
    // Callers should enter at an appropriate offset so that live registers
    // holding arguments and return values (c0-c7) are preserved.
clean:
    mov x0, #0
    mov x1, #0
    mov x2, #0
    mov x3, #0
    mov x4, #0
    mov x5, #0
    mov x6, #0
    mov x7, #0
    mov x8, #0
    mov x9, #0
    mov x10, #0
    mov x11, #0
    mov x12, #0
    mov x13, #0
    mov x14, #0
    mov x15, #0
    mov x16, #0
    mov x17, #0
    // x18 is the "platform register" (for some platforms). If so, it needs to
    // be preserved, but here we assume that only the lower 64 bits are
    // required.
    mov x18, x18
    // x19-x29 are callee-saved, but only the lower 64 bits.
    mov x19, x19
    mov x20, x20
    mov x21, x21
    mov x22, x22
    mov x23, x23
    mov x24, x24
    mov x25, x25
    mov x26, x26
    mov x27, x27
    mov x28, x28
    mov x29, x29  // FP
    // We need LR (x30) to return. The call to this helper already cleaned it.
    // Don't replace SP; this needs special handling by the caller anyway.
    ret

