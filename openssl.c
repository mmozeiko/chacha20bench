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

// https://github.com/openssl/openssl/blob/master/crypto/aes/asm/aesni-x86_64.pl

typedef struct aes_key_st {
    unsigned int rd_key[4 * (14 + 1)];
    int rounds;
} AES_KEY;

__attribute__((ms_abi))
void aesni_set_encrypt_key(const unsigned char* inp, int bits, AES_KEY* const key);

__attribute__((sysv_abi))
void aesni_ctr32_encrypt_blocks(const void* in, void* out, size_t blocks, const AES_KEY* key, const char* ivec);

void aes256ni_openssl(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    AES_KEY __attribute__((aligned(16))) k;
    aesni_set_encrypt_key(key, 256, &k);

    uint32_t __attribute__((aligned(16))) iv[4] = { 0, 0, 0, (uint32_t)counter};
    aesni_ctr32_encrypt_blocks(input, output, size / 16, &k, (char*)iv);
}
