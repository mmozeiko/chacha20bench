#include <stdint.h>
#include <string.h>
#include <intrin.h>

// https://github.com/openssl/openssl/blob/master/include/crypto/chacha.h
// https://github.com/openssl/openssl/blob/master/providers/implementations/ciphers/cipher_chacha20.h
// https://github.com/openssl/openssl/blob/master/providers/implementations/ciphers/cipher_chacha20_hw.c
// https://github.com/openssl/openssl/blob/master/crypto/chacha/asm/chacha-x86_64.pl
// https://github.com/openssl/openssl/blob/master/crypto/x86_64cpuid.pl

unsigned int OPENSSL_ia32cap_P[4];

#include "openssl/cipher_chacha20_hw.c"

void chacha20_openssl(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    static int init = 0;
    if (!init)
    {
        __attribute__((sysv_abi)) uint64_t OPENSSL_ia32_cpuid(unsigned int*);
        uint64_t vec = OPENSSL_ia32_cpuid(OPENSSL_ia32cap_P);
        OPENSSL_ia32cap_P[0] = (unsigned int)vec | (1 << 10);
        OPENSSL_ia32cap_P[1] = (unsigned int)(vec >> 32);
#ifndef __AVX512F__
        OPENSSL_ia32cap_P[1] = OPENSSL_ia32cap_P[1] & ~16;
        OPENSSL_ia32cap_P[2] = OPENSSL_ia32cap_P[2] & ~(1<<31);
#endif
        init = 1;
    }

    PROV_CHACHA20_CTX ctx;
    ctx.iv_set = 1;
    *(uint64_t*)&ctx.oiv[0] = 0;
    *(uint64_t*)&ctx.oiv[8] = counter;

    chacha20_initkey(&ctx, key, CHACHA_KEY_SIZE);
    chacha20_initiv(&ctx);
    chacha20_cipher(&ctx, output, input, size);
}
