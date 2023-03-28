@echo off

clang-cl -c -Z7 -O2 -mavx512f dolbeau.c -Fodolbeau_avx512.o
clang-cl -c -Z7 -O2 -mavx512f kernel.c -Fokernel_avx512.o
clang-cl -c -Z7 -O2 -mvaes -mavx2 vaes_avx2.c -Fovaes_avx2.o
clang-cl -c -Z7 -O2 -mvaes -mavx512f -mavx512bw vaes_avx512.c -Fovaes_avx512.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/x86_64/const.asm -o const.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/x86_64/aes_keyexp_256.asm -o aes_keyexp_256.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/avx_t1/aes128_cntr_by8_avx.asm -o aes128_cntr_by8_avx.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/avx_t1/aes256_cntr_by8_avx.asm -o aes256_cntr_by8_avx.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/avx512_t2/aes_cntr_api_by16_vaes_avx512.asm -o aes_cntr_api_by16_vaes_avx512.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/avx2_t1/chacha20_avx2.asm -o intelmb_chacha20_avx2.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/avx512_t1/chacha20_avx512.asm -o intelmb_chacha20_avx512.o
nasm -g -fwin64 -DWIN_ABI -Iintelmb intelmb/sse_t1/chacha20_sse.asm -o intelmb_chacha20_sse.o

clang-cl.exe                        ^
  -Z7 -O2 -W3 -arch:AVX2            ^
  -fuse-ld=lld                      ^
  main.c                            ^
  ref.c                             ^
  dolbeau.c                         ^
  dolbeau_avx512.o                  ^
  sodium.c                          ^
  kernel.c                          ^
  kernel_avx512.o                   ^
  openssl.c                         ^
  gcrypt.c                          ^
  -Iintelmb intelmb.c               ^
  nss.c                             ^
  aesni.c                           ^
  kernel/chacha-avx2-x86_64.S       ^
  kernel/chacha-avx512vl-x86_64.S   ^
  kernel/chacha-ssse3-x86_64.S      ^
  openssl/x86_64cpuid.S             ^
  openssl/chacha-x86_64.S           ^
  openssl/aesni-x86_64.S            ^
  gcrypt/chacha20-amd64-avx2.S      ^
  gcrypt/chacha20-amd64-ssse3.S     ^
  vaes_avx2.o                       ^
  vaes_avx512.o                     ^
  const.o                           ^
  aes_keyexp_256.o                  ^
  aes128_cntr_by8_avx.o             ^
  aes256_cntr_by8_avx.o             ^
  aes_cntr_api_by16_vaes_avx512.o   ^
  intelmb_chacha20_avx2.o           ^
  intelmb_chacha20_avx512.o         ^
  intelmb_chacha20_sse.o            ^
  -Febench.exe                      ^
  -link -stack:10485760,10485760

del /s *.o >nul
