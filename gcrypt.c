#include <stdint.h>
#include <intrin.h>

// https://github.com/gpg/libgcrypt/blob/master/cipher/chacha20.c
// https://github.com/gpg/libgcrypt/blob/master/cipher/chacha20-amd64-avx2.S
// https://github.com/gpg/libgcrypt/blob/master/cipher/chacha20-amd64-ssse3.S
// https://github.com/gpg/libgcrypt/blob/master/cipher/asm-common-amd64.h
// https://github.com/gpg/libgcrypt/blob/master/cipher/asm-poly1305-amd64.h

typedef uint8_t byte;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int gcry_err_code_t;
typedef void cipher_bulk_ops_t;

#define HAVE_COMPATIBLE_GCC_WIN64_PLATFORM_AS 1
#define HAVE_GCC_INLINE_ASM_SSSE3 1
#define HAVE_GCC_INLINE_ASM_AVX2 1

#define GPG_ERR_SELFTEST_FAILED  -1
#define GPG_ERR_INV_KEYLEN       -2

#define HWF_INTEL_SSSE3 1
#define HWF_INTEL_AVX2  2

static unsigned int _gcry_get_hw_features()
{
    return HWF_INTEL_SSSE3 | HWF_INTEL_AVX2;
}

#define rol(x,c) __builtin_rotateleft32((x),(c))

static void buf_put_le32(void* ptr, u32 x) { *(u32*)ptr = x; }
static void buf_put_he32(void* ptr, u32 x) { *(u32*)ptr = x; }
static void buf_put_he64(void* ptr, u64 x) { *(u64*)ptr = x; }

#define buf_get_le32(ptr) (*(u32*)(ptr))
#define buf_get_he32(ptr) buf_get_le32(ptr)
#define buf_get_he64(ptr) (*(u64*)(ptr))

#define log_info(...)
#define log_error(...) __debugbreak()
#define _gcry_burn_stack(...)
#define gcry_assert(...)

static inline void
buf_xor(void* _dst, const void* _src1, const void* _src2, size_t len)
{
    byte* dst = _dst;
    const byte* src1 = _src1;
    const byte* src2 = _src2;

    while (len >= sizeof(u64))
    {
        buf_put_he64(dst, buf_get_he64(src1) ^ buf_get_he64(src2));
        dst += sizeof(u64);
        src1 += sizeof(u64);
        src2 += sizeof(u64);
        len -= sizeof(u64);
    }

    if (len > sizeof(u32))
    {
        buf_put_he32(dst, buf_get_he32(src1) ^ buf_get_he32(src2));
        dst += sizeof(u32);
        src1 += sizeof(u32);
        src2 += sizeof(u32);
        len -= sizeof(u32);
    }

    for (; len; len--)
        *dst++ = *src1++ ^ *src2++;
}

#include "gcrypt/chacha20.c"

void chacha20_gcrypt(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    CHACHA20_context_t ctx;
    chacha20_do_setkey(&ctx, key, CHACHA20_MAX_KEY_SIZE);
    chacha20_ivsetup(&ctx, (byte*)&counter, CHACHA20_MIN_IV_SIZE);
    chacha20_encrypt_stream(&ctx, output, input, size);
}
