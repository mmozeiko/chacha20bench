#include <stdint.h>
#include <stddef.h>

// http://www.dolbeau.name/dolbeau/crypto/crypto_core-intrinsics.tgz
// http://bench.cr.yp.to/supercop/supercop-20210604.tar.xz

#include "dolbeau/chacha.c"

void chacha20_dolbeau(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    ECRYPT_ctx ctx;
    ECRYPT_keysetup(&ctx, key, 256, 128);
    ECRYPT_ivsetup(&ctx, (uint8_t*)&counter);
    ECRYPT_encrypt_bytes(&ctx, input, output, size);
}
