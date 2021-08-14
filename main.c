#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#define _m_prefetchw _m_prefetchw1
#include <intrin.h>
#else
#include <sys/mman.h>
#include <x86intrin.h>
#endif

void chacha20_ref(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);
void chacha20_dolbeau(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);
void chacha20_sodium(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);
void chacha20_kernel(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);
void chacha20_openssl(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);
void chacha20_gcrypt(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);
void aes256ni(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);

typedef void chacha20_fn(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size);

typedef struct {
    const char* name;
    chacha20_fn* f;
} chacha20;

static chacha20 chachas[] = {
    { "ref",      &chacha20_ref     },
    { "dolbeau",  &chacha20_dolbeau },
    { "sodium",   &chacha20_sodium  },
    { "kernel",   &chacha20_kernel  },
    { "openssl",  &chacha20_openssl },
    { "gcrypt",   &chacha20_gcrypt  },
    { "aes256ni", &aes256ni         },
};

#define CHACHAS_COUNT (sizeof(chachas)/sizeof(*chachas))

void test(chacha20 c, const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    c.f(key, counter, input, output, size);
    
    printf("%-10s ", c.name);
    
    // print last 16 bytes
    for (size_t i=0; i<16; i++)
    {
        printf("%02hhx", output[size-16+i]);
    }
    printf("\n");
}

// don't inline so compiler cannot discard output
void __attribute__((noinline)) run_bench(chacha20_fn* f, const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size, size_t iters)
{
    for (size_t i=0; i<iters; i++)
    {
        f(key, counter, input, output, size);   
    }
}

void bench(chacha20 c, const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size, size_t iters)
{
    unsigned int tmp;
    uint64_t a = __rdtscp(&tmp);
    run_bench(c.f, key, counter, input, output, size, iters);
    uint64_t b = __rdtscp(&tmp);
    
    printf("%-10s %.2f cycles/byte\n", c.name, (double)(b - a) / size / iters);   
}

int main()
{
#ifdef __AVX512F__
    printf("*** AVX512 enabled\n");
#endif

    size_t iters = 1024*1024;
    
    size_t size = 4096;
#ifdef WIN32
    uint8_t* input = VirtualAlloc(NULL, size * 2, MEM_COMMIT, PAGE_READWRITE);
#else
    uint8_t* input = mmap(NULL, size * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
#endif
    uint8_t* output = input + size;

    uint8_t key[32];
    for (int i=0; i<32; i++) key[i] = (uint8_t)i;

    printf("*** TESTS (check if bytes match) ***\n");
    for (size_t i=0; i<CHACHAS_COUNT-1; i++)
    {
        test(chachas[i], key, 0xfedcba876543210, input, output, size);
        memset(output, 0, size);
    }

    printf("*** BENCH ***\n");
    for (size_t i=0; i<CHACHAS_COUNT; i++)
    {
        bench(chachas[i], key, 0, input, output, size, iters);
    }   
}
