#!/bin/sh

clang -fuse-ld=lld                  \
  -g -O2 -Wall  -mssse3 -mavx2      \
  main.c                            \
  ref.c                             \
  dolbeau.c                         \
  sodium.c                          \
  kernel.c                          \
  openssl.c                         \
  gcrypt.c                          \
  nss.c                             \
  aesni.c                           \
  kernel/chacha-avx2-x86_64.S       \
  kernel/chacha-ssse3-x86_64.S      \
  openssl/x86_64cpuid.S             \
  openssl/chacha-x86_64.S           \
  gcrypt/chacha20-amd64-avx2.S      \
  gcrypt/chacha20-amd64-ssse3.S     \
  -o bench.exe

clang -fuse-ld=lld                  \
  -g -O2 -Wall -mssse3 -mavx512f   \
  main.c                            \
  ref.c                             \
  dolbeau.c                         \
  sodium.c                          \
  kernel.c                          \
  openssl.c                         \
  gcrypt.c                          \
  nss.c                             \
  aesni.c                           \
  kernel/chacha-avx2-x86_64.S       \
  kernel/chacha-avx512vl-x86_64.S   \
  kernel/chacha-ssse3-x86_64.S      \
  openssl/x86_64cpuid.S             \
  openssl/chacha-x86_64.S           \
  gcrypt/chacha20-amd64-avx2.S      \
  gcrypt/chacha20-amd64-ssse3.S     \
  -o bench-avx512.exe

