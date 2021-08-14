#include <stdint.h>
#include <stddef.h>

// https://github.com/torvalds/linux/blob/master/arch/x86/crypto/chacha_glue.c
// https://github.com/torvalds/linux/blob/master/arch/x86/crypto/chacha-avx2-x86_64.S
// https://github.com/torvalds/linux/blob/master/arch/x86/crypto/chacha-ssse3-x86_64.S
// https://github.com/torvalds/linux/blob/master/include/crypto/chacha.h
// https://github.com/torvalds/linux/blob/master/include/linux/linkage.h

typedef uint8_t u8;
typedef uint32_t u32;

#define get_unaligned_le32(ptr) (*(uint32_t*)(ptr))
#define asmlinkage __attribute__((sysv_abi))
#define min(a,b) ( (a)<(b) ? (a) : (b) )
#define round_up(a,b) ( ((a)+(b)-1) & ((b)-1) )

#include "kernel/chacha.h"
#include "kernel/chacha_glue.c"

#ifdef __AVX512F__
#define NAME chacha20_kernel_avx512
#else
#define NAME chacha20_kernel
#endif

void NAME(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    u32 state[CHACHA_STATE_WORDS];
    
    uint64_t iv[] = { 0, counter };
    chacha_init_generic(state, (u32*)key, (u8*)iv);
    chacha_dosimd(state, output, input, size, 20);
}
