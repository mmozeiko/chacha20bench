@echo off

clang-cl -c -Z7 -O2 -mavx512f dolbeau.c -Fodolbeau_avx512.o
clang-cl -c -Z7 -O2 -mavx512f kernel.c -Fokernel_avx512.o
clang-cl -c -Z7 -O2 -mvaes -mavx2 vaes_avx2.c -Fovaes_avx2.o
clang-cl -c -Z7 -O2 -mvaes -mavx512f -mavx512bw vaes_avx512.c -Fovaes_avx512.o

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
  nss.c                             ^
  aesni.c                           ^
  aesni-openssl.c                   ^
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
  -Febench.exe                      ^
  -link -stack:10485760,10485760

del /s *.o >nul
