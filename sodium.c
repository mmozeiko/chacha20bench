#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <immintrin.h>

// https://github.com/jedisct1/libsodium/tree/master/src/libsodium/crypto_stream/chacha20/dolbeau

#define SODIUM_STATIC
#ifndef _MSC_VER
#define HAVE_AVX2INTRIN_H 1
#define HAVE_EMMINTRIN_H  1
#define HAVE_TMMINTRIN_H  1
#define HAVE_SMMINTRIN_H  1
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "sodium/chacha20_dolbeau-avx2.c"
#pragma clang diagnostic pop

void sodium_memzero(void * const pnt, const size_t len)
{
    memset(pnt, 0, len);
}

void chacha20_sodium(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    chacha_ctx ctx;
    chacha_keysetup(&ctx, key);
    chacha_ivsetup(&ctx, (uint8_t*)&counter, NULL);
    chacha20_encrypt_bytes(&ctx, input, output, size);
}
