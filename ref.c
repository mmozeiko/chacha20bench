#include <stdint.h>
#include <stddef.h>

// https://cr.yp.to/chacha.html
// https://cr.yp.to/streamciphers/timings/estreambench/submissions/salsa20/chacha8/merged/chacha.c
// rounds in chacha.c changed from 8 to 20 (ChaCha8 -> ChaCha20)

typedef uint8_t u8;
typedef uint32_t u32;

#define U32V(v) ((u32)(v))
#define ROTL32(x,c) __builtin_rotateleft32((x),(c))
#define U8TO32_LITTLE(ptr) (*(u32*)(ptr))
#define U32TO8_LITTLE(ptr,x) *(u32*)(ptr) = x

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "ref/chacha.c"
#pragma clang diagnostic pop

void chacha20_ref(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    ECRYPT_ctx ctx;
    ECRYPT_keysetup(&ctx, key, 256, 128);
    ECRYPT_ivsetup(&ctx, (uint8_t*)&counter);
    ECRYPT_encrypt_bytes(&ctx, input, output, size);
}
