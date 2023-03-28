#include <stdint.h>
#include <stddef.h>
#include <string.h>

#include "intelmb/include/intel-ipsec-mb.h"
#include "intelmb/include/chacha20_poly1305.h"
#include "intelmb/include/arch_avx_type1.h"
#include "intelmb/include/arch_avx512_type2.h"

// https://github.com/intel/intel-ipsec-mb/tree/main/lib/include

void chacha20_intelmb_sse4(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    struct chacha20_poly1305_context_data ctx = { 0 };
    uint32_t iv[3] = { 0, counter, counter >> 32 }; // TODO: fix iv to match with others
    memcpy(ctx.IV, iv, sizeof(iv));
    chacha20_enc_dec_ks_sse(input, output, size, key, &ctx);
}

void chacha20_intelmb_avx2(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    struct chacha20_poly1305_context_data ctx = { 0 };
    uint32_t iv[3] = { 0, counter, counter >> 32 }; // TODO: fix iv to match with others
    memcpy(ctx.IV, iv, sizeof(iv));
    chacha20_enc_dec_ks_avx2(input, output, size, key, &ctx);
}

void chacha20_intelmb_avx512(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    struct chacha20_poly1305_context_data ctx = { 0 };
    uint32_t iv[3] = { 0, counter, counter >> 32 }; // TODO: fix iv to match with others
    memcpy(ctx.IV, iv, sizeof(iv));
    chacha20_enc_dec_ks_avx512(input, output, size, key, &ctx);
}

void aes256ni_intelmb(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    uint8_t __attribute__((aligned(64))) expanded[16 * 15];
    aes_keyexp_256_enc_avx(key, expanded);

    uint32_t iv[4] = { 0, 0, 0, (uint32_t)counter };
    aes_cntr_256_avx(input, iv, expanded, output, size, sizeof(iv));
}

void vaes256_intelmb_avx512(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    uint8_t __attribute__((aligned(64))) expanded[16 * 15];
    aes_keyexp_256_enc_avx(key, expanded);

    uint32_t iv[4] = { 0, 0, 0, (uint32_t)counter };

    IMB_JOB job = { 0 };
    job.enc_keys = expanded;
    job.key_len_in_bytes = IMB_KEY_256_BYTES;
    job.src = input;
    job.dst = output;
    job.msg_len_to_cipher_in_bytes = size;
    job.iv = (uint8_t*)iv;
    job.iv_len_in_bytes = sizeof(iv);
    job.cipher_mode = IMB_CIPHER_CNTR;
    job.cipher_direction = IMB_DIR_ENCRYPT;
    job.hash_alg = IMB_AUTH_NULL;

    aes_cntr_256_submit_vaes_avx512(&job);
}
