@echo off

clang-cl.exe                        ^
  -Z7 -O2 -W3 -arch:AVX2            ^
  -fuse-ld=lld -GS- -Gs999999       ^
  main.c                            ^
  ref.c                             ^
  dolbeau.c                         ^
  sodium.c                          ^
  kernel.c                          ^
  openssl.c                         ^
  gcrypt.c                          ^
  nss.c                             ^
  aesni.c                           ^
  kernel/chacha-avx2-x86_64.S       ^
  kernel/chacha-ssse3-x86_64.S      ^
  openssl/x86_64cpuid.S             ^
  openssl/chacha-x86_64.S           ^
  gcrypt/chacha20-amd64-avx2.S      ^
  gcrypt/chacha20-amd64-ssse3.S     ^
  -Febench.exe                      ^
  -link -stack:10485760,10485760

clang-cl.exe                        ^
  -Z7 -O2 -W3 -arch:AVX512          ^
  -fuse-ld=lld -GS- -Gs999999       ^
  main.c                            ^
  ref.c                             ^
  dolbeau.c                         ^
  sodium.c                          ^
  kernel.c                          ^
  openssl.c                         ^
  gcrypt.c                          ^
  nss.c                             ^
  aesni.c                           ^
  kernel/chacha-avx2-x86_64.S       ^
  kernel/chacha-avx512vl-x86_64.S   ^
  kernel/chacha-ssse3-x86_64.S      ^
  openssl/x86_64cpuid.S             ^
  openssl/chacha-x86_64.S           ^
  gcrypt/chacha20-amd64-avx2.S      ^
  gcrypt/chacha20-amd64-ssse3.S     ^
  -Febench-avx512.exe               ^
  -link -stack:10485760,10485760
