#include <stdint.h>
#include <stddef.h>
#include <tmmintrin.h>
#include <wmmintrin.h>

#define aesni_fun static __attribute__ ((__target__("aes")))

// https://www.intel.com/content/dam/doc/white-paper/advanced-encryption-standard-new-instructions-set-paper.pdf

aesni_fun void KEY_256_ASSIST_1(__m128i* temp1, __m128i * temp2)
{
    __m128i temp4;
    *temp2 = _mm_shuffle_epi32(*temp2, 0xff);
    temp4 = _mm_slli_si128 (*temp1, 0x4);
    *temp1 = _mm_xor_si128 (*temp1, temp4);
    temp4 = _mm_slli_si128 (temp4, 0x4);
    *temp1 = _mm_xor_si128 (*temp1, temp4);
    temp4 = _mm_slli_si128 (temp4, 0x4);
    *temp1 = _mm_xor_si128 (*temp1, temp4);
    *temp1 = _mm_xor_si128 (*temp1, *temp2);
}

aesni_fun void KEY_256_ASSIST_2(__m128i* temp1, __m128i * temp3)
{
    __m128i temp2,temp4;
    temp4 = _mm_aeskeygenassist_si128 (*temp1, 0x0);
    temp2 = _mm_shuffle_epi32(temp4, 0xaa);
    temp4 = _mm_slli_si128 (*temp3, 0x4);
    *temp3 = _mm_xor_si128 (*temp3, temp4);
    temp4 = _mm_slli_si128 (temp4, 0x4);
    *temp3 = _mm_xor_si128 (*temp3, temp4);
    temp4 = _mm_slli_si128 (temp4, 0x4);
    *temp3 = _mm_xor_si128 (*temp3, temp4);
    *temp3 = _mm_xor_si128 (*temp3, temp2);
}

aesni_fun void AES_256_Key_Expansion(const unsigned char *userkey,  unsigned char *key)
{
    __m128i temp1, temp2, temp3;
    __m128i *Key_Schedule = (__m128i*)key;
    temp1 = _mm_loadu_si128((__m128i*)userkey);
    temp3 = _mm_loadu_si128((__m128i*)(userkey+16));
    Key_Schedule[0] = temp1;
    Key_Schedule[1] = temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x01);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[2]=temp1;
    KEY_256_ASSIST_2(&temp1, &temp3);
    Key_Schedule[3]=temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x02);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[4]=temp1;
    KEY_256_ASSIST_2(&temp1, &temp3);
    Key_Schedule[5]=temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x04);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[6]=temp1;
    KEY_256_ASSIST_2(&temp1, &temp3);
    Key_Schedule[7]=temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x08);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[8]=temp1;
    KEY_256_ASSIST_2(&temp1, &temp3);
    Key_Schedule[9]=temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x10);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[10]=temp1;
    KEY_256_ASSIST_2(&temp1, &temp3);
    Key_Schedule[11]=temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x20);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[12]=temp1;
    KEY_256_ASSIST_2(&temp1, &temp3);
    Key_Schedule[13]=temp3;
    temp2 = _mm_aeskeygenassist_si128 (temp3,0x40);
    KEY_256_ASSIST_1(&temp1, &temp2);
    Key_Schedule[14]=temp1;
}

aesni_fun void AES_CTR_encrypt(const unsigned char *in, unsigned char *out, uint32_t counter, unsigned long length, const unsigned char *key, int number_of_rounds)
{
    int i,j; 
    if (length%16) length = length/16 + 1;
    else           length/=16;

    // these counter calculations matches openssl aesni implementation
    __m128i ONE = _mm_setr_epi32(0,0,0,1);
    __m128i BSWAP32 = _mm_setr_epi8(3,2,1,0,7,6,5,4,11,10,9,8,15,14,13,12);
    __m128i ctr_block = _mm_setr_epi32(0, 0, 0, counter);
    ctr_block = _mm_shuffle_epi8(ctr_block, BSWAP32);

    __m128i k[15];
    for (int j = 0; j <= number_of_rounds; j++)
    {
        k[j] = ((__m128i*)key)[j];
    }

    for(i=0; i < length; i++)
    {
        __m128i tmp = _mm_shuffle_epi8(ctr_block, BSWAP32);
        ctr_block = _mm_add_epi64(ctr_block, ONE);
        tmp = _mm_xor_si128(tmp, k[0]);
        for (j=1; j <number_of_rounds; j++)
        {
            tmp = _mm_aesenc_si128 (tmp, k[j]);
        }
        tmp = _mm_aesenclast_si128 (tmp, k[j]);
        tmp = _mm_xor_si128(tmp,_mm_loadu_si128((__m128i*)(in + i*16)));
        _mm_storeu_si128 ((__m128i*)(out + i * 16),tmp);
    }
}
  
void aes256ni(const uint8_t* key, uint64_t counter, const uint8_t* input, uint8_t* output, size_t size)
{
    unsigned char __attribute__((aligned(16))) ctx[16*15];
    AES_256_Key_Expansion(key, ctx);
    AES_CTR_encrypt(input, output, (uint32_t)counter, size, ctx, 14);
}
