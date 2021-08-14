#include <stdint.h>
#include <stddef.h>

// https://hg.mozilla.org/projects/nss/file/tip/lib/freebl/verified/Hacl_Chacha20_Vec256.c

#include "nss/Hacl_Chacha20_Vec256.c"
#include "nss/Hacl_Chacha20.c"

void chacha20_nss(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    uint32_t n[3] = { 0, counter, counter >> 32 };
    Hacl_Chacha20_Vec256_chacha20_encrypt_256(size, output, (uint8_t*)input, (uint8_t*)key, (uint8_t*)n, 0);
}
