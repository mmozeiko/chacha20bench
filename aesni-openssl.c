#include <stdint.h>
#include <stddef.h>

// https://github.com/openssl/openssl/blob/master/crypto/aes/asm/aesni-x86_64.pl

typedef struct aes_key_st {
    unsigned int rd_key[4 * (14 + 1)];
    int rounds;
} AES_KEY;

__attribute__((sysv_abi))
void aesni_set_encrypt_key(const unsigned char* inp, int bits, AES_KEY* const key);

__attribute__((sysv_abi))
void aesni_ctr32_encrypt_blocks(const void* in, void* out, size_t blocks, const AES_KEY* key, const char* ivec);

void aes256ni_openssl(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    AES_KEY __attribute__((aligned(16))) k;
    aesni_set_encrypt_key(key, 256, &k);

    // this may be not completely correct due to how counter is incremented
    // I have not checked result, use this only for benchmarking
    uint64_t __attribute__((aligned(16))) iv[2] = { 0, counter };
    aesni_ctr32_encrypt_blocks(input, output, size / 16, &k, (char*)iv);
}
