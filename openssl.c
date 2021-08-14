#include <stdint.h>
#include <stddef.h>
#include <string.h>

// https://github.com/openssl/openssl/blob/master/include/crypto/chacha.h
// https://github.com/openssl/openssl/blob/master/providers/implementations/ciphers/cipher_chacha20.h
// https://github.com/openssl/openssl/blob/master/providers/implementations/ciphers/cipher_chacha20_hw.c
// https://github.com/openssl/openssl/blob/master/crypto/chacha/asm/chacha-x86_64.pl
// https://github.com/openssl/openssl/blob/master/crypto/x86_64cpuid.pl

#include "openssl/cipher_chacha20_hw.c"

void chacha20_openssl(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    PROV_CHACHA20_CTX ctx;
    ctx.iv_set = 1;
    *(uint64_t*)&ctx.oiv[0] = 0;
    *(uint64_t*)&ctx.oiv[8] = counter;

    chacha20_initkey(&ctx, key, CHACHA_KEY_SIZE);
    chacha20_initiv(&ctx);
    chacha20_cipher(&ctx, output, input, size);
}
