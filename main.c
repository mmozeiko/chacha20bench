#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32

#include <windows.h>
#define _m_prefetchw _m_prefetchw1
#include <intrin.h>

    static uint64_t ticks()
    {
        LARGE_INTEGER c;
        QueryPerformanceCounter(&c);
        return c.QuadPart;
    }

    static uint64_t freq()
    {
        LARGE_INTEGER f;
        QueryPerformanceFrequency(&f);
        return f.QuadPart;
    }

#else

#include <time.h>
#include <sys/mman.h>
#include <x86intrin.h>

    static uint64_t ticks()
    {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        return ts.tv_sec * 1000000000 + ts.tv_nsec;
    }

    static uint64_t freq()
    {
        return 1000000000;
    }

#endif

#include <cpuid.h>

#define FN(name) void name(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
FN(chacha20_ref);
FN(chacha20_dolbeau);
FN(chacha20_dolbeau_avx512);
FN(chacha20_sodium);
FN(chacha20_kernel);
FN(chacha20_kernel_avx512);
FN(chacha20_openssl);
FN(chacha20_openssl_avx512);
FN(chacha20_gcrypt);
FN(chacha20_nss);
FN(aes256ni);
FN(aes256ni_openssl);
FN(vaes256_avx2);
FN(vaes256_avx512);
typedef FN(fnptr);
#undef FN

typedef struct {
    const char* name;
    fnptr* f;
    int avx512;
    int vaes;
} function;

static function functions[] = {
    { "ref",              &chacha20_ref,             0, 0 },
    { "dolbeau",          &chacha20_dolbeau,         0, 0 },
    { "dolbeau-avx512",   &chacha20_dolbeau_avx512,  1, 0 },
    { "sodium",           &chacha20_sodium,          0, 0 },
    { "kernel",           &chacha20_kernel,          0, 0 },
    { "kernel-avx512",    &chacha20_kernel_avx512,   1, 0 },
    { "openssl",          &chacha20_openssl,         0, 0 },
    { "openssl-avx512",   &chacha20_openssl,         1, 0 },
    { "gcrypt",           &chacha20_gcrypt,          0, 0 },
    { "nss",              &chacha20_nss,             0, 0 },
    { "aes256ni",         &aes256ni,                 0, 0 },
    { "aes256ni_openssl", &aes256ni_openssl,         0, 0 },
    { "vaes256-avx2",     &vaes256_avx2,             0, 1 },
    { "vaes256-avx512",   &vaes256_avx512,           1, 1 },
};

#define FUNCTION_COUNT (sizeof(functions)/sizeof(*functions))

static int HAS_AVX512;
static int HAS_VAES;

uint32_t OPENSSL_ia32cap_P[4];

static void enable_avx512(int enable)
{
    if (enable && HAS_AVX512)
    {
        OPENSSL_ia32cap_P[2] |= (1<<16|1<<31);
    }
    else
    {
        // bits that openssl uses to dectect avx512
        OPENSSL_ia32cap_P[2] &= ~(1<<16|1<<31);
    }
}

static uint8_t* test_ref;

void test(function f, const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    if ((f.avx512 && !HAS_AVX512) || (f.vaes && !HAS_VAES))
    {
        printf("%-18s N/A\n", f.name);
    }
    else
    { 
        enable_avx512(f.avx512);
        f.f(key, counter, input, output, size);

        // print last 16 bytes
        printf("%-18s ", f.name);
        for (size_t i=0; i<16; i++)
        {
            printf("%02hhx", output[size-16+i]);
        }

        if (output != test_ref && f.f != &aes256ni && f.f != &aes256ni_openssl && f.f != vaes256_avx2 && f.f != vaes256_avx512)
        {
            printf(" %s", memcmp(output, test_ref, size) == 0 ? "OK" : "** ERROR **");
        }
        printf("\n");
    }
}

// don't inline so compiler cannot discard output
void __attribute__((noinline)) run_bench(fnptr* f, const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size, size_t iters)
{
    for (size_t i=0; i<iters; i++)
    {
        f(key, counter, input, output, size);   
    }
}

void bench(function f, const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size, size_t iters)
{
    if ((f.avx512 && !HAS_AVX512) || (f.vaes && !HAS_VAES))
    {
        printf("%-18s N/A\n", f.name);
    }
    else
    {
        enable_avx512(f.avx512);

        unsigned int tmp;
        uint64_t t1 = ticks();
        uint64_t a = __rdtscp(&tmp);
        run_bench(f.f, key, counter, input, output, size, iters);
        uint64_t b = __rdtscp(&tmp);
        uint64_t t2 = ticks();

        double secs = (double)(t2 - t1) / freq();
        
        double cpb = (double)(b - a) / size / iters;
        double gb = (double)size * iters / secs / 1024 / 1024 / 1024;
        printf("%-18s %.2f cycles/byte, %5.2f GiB/s\n", f.name, cpb, gb);
    }
}

int main()
{
    __attribute__((sysv_abi)) uint64_t OPENSSL_ia32_cpuid(unsigned int*);
    uint64_t vec = OPENSSL_ia32_cpuid(OPENSSL_ia32cap_P);
    OPENSSL_ia32cap_P[0] = (unsigned int)vec | (1 << 10);
    OPENSSL_ia32cap_P[1] = (unsigned int)(vec >> 32);

    unsigned int eax, ebx, ecx, edx;
    __cpuid_count(7, 0, eax, ebx, ecx, edx);
    HAS_AVX512 = (ebx & (1 << 16)) != 0;
    HAS_VAES = (ecx & (1 << 9)) != 0;

    size_t iters = 1024*1024;
    size_t size = 4096;
#ifdef WIN32
    uint8_t* input = VirtualAlloc(NULL, size * 3, MEM_COMMIT, PAGE_READWRITE);
#else
    uint8_t* input = mmap(NULL, size * 3, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
#endif
    uint8_t* output = input + size;
    test_ref = output + size;

    uint8_t key[32];
    for (int i=0; i<32; i++) key[i] = (uint8_t)i;

    printf("*** TESTS (check if bytes match) ***\n");
    for (size_t i=0; i<FUNCTION_COUNT; i++)
    {
        test(functions[i], key, 0xfedcba876543210, input, i==0 ? test_ref : output, size);
        memset(output, 0, size);
    }

    printf("*** BENCH ***\n");
    for (size_t i=0; i<FUNCTION_COUNT; i++)
    {
        bench(functions[i], key, 0, input, output, size, iters);
    }
}
