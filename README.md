chacha20 benchmarks & comparison with AESNI & VAES.

Results on Intel i7-1185G7 @ 3.00GHz (turbo boost OFF):

```
ref                5.78 cycles/byte,  0.48 GiB/s
dolbeau            1.29 cycles/byte,  2.17 GiB/s
dolbeau-avx512     0.67 cycles/byte,  4.17 GiB/s
sodium             1.30 cycles/byte,  2.14 GiB/s
kernel             1.22 cycles/byte,  2.28 GiB/s
kernel-avx512      0.88 cycles/byte,  3.19 GiB/s
openssl            1.17 cycles/byte,  2.38 GiB/s
openssl-avx512     0.59 cycles/byte,  4.72 GiB/s
gcrypt             1.16 cycles/byte,  2.40 GiB/s
nss                1.39 cycles/byte,  2.01 GiB/s
aes256ni           0.58 cycles/byte,  4.85 GiB/s
aes256ni_openssl   0.48 cycles/byte,  5.78 GiB/s
vaes256-avx2       0.32 cycles/byte,  8.69 GiB/s
vaes256-avx512     0.27 cycles/byte, 10.40 GiB/s
```

