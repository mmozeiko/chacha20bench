#!/bin/sh

clang -c -g -O2 -mavx512f dolbeau.c -o dolbeau_avx512.o
clang -c -g -O2 -mavx512f kernel.c -o kernel_avx512.o
clang -c -g -O2 -mvaes -mavx2 vaes_avx2.c -o vaes_avx2.o
clang -c -g -O2 -mvaes -mavx512f -mavx512bw vaes_avx512.c -o vaes_avx512.o

clang -fuse-ld=lld                  \
  -g -O2 -Wall  -mssse3 -mavx2      \
  main.c                            \
  ref.c                             \
  dolbeau.c                         \
  dolbeau_avx512.o                  \
  sodium.c                          \
  kernel.c                          \
  kernel_avx512.o                   \
  openssl.c                         \
  gcrypt.c                          \
  nss.c                             \
  aesni.c                           \
  aesni-openssl.c                   \
  kernel/chacha-avx2-x86_64.S       \
  kernel/chacha-avx512vl-x86_64.S   \
  kernel/chacha-ssse3-x86_64.S      \
  openssl/x86_64cpuid.S             \
  openssl/chacha-x86_64.S           \
  openssl/aesni-x86_64.S            \
  gcrypt/chacha20-amd64-avx2.S      \
  gcrypt/chacha20-amd64-ssse3.S     \
  vaes_avx2.o                       \
  vaes_avx512.o                     \
  -o bench.exe

rm *.o
