chacha20 benchmarks & comparison with AESNI & VAES.

Results on Intel i7-1185G7 @ 3.00GHz (turbo boost OFF):

```
ref                  5.74 cycles/byte,  0.49 GiB/s
dolbeau              1.28 cycles/byte,  2.17 GiB/s
dolbeau-avx512       0.67 cycles/byte,  4.18 GiB/s
sodium               1.29 cycles/byte,  2.17 GiB/s
kernel               1.22 cycles/byte,  2.29 GiB/s
kernel-avx512        0.88 cycles/byte,  3.17 GiB/s
openssl              1.17 cycles/byte,  2.39 GiB/s
openssl-avx512       0.59 cycles/byte,  4.74 GiB/s
imb-sse4             2.36 cycles/byte,  1.18 GiB/s
imb-avx2             1.22 cycles/byte,  2.29 GiB/s
imb-avx512           0.57 cycles/byte,  4.85 GiB/s
gcrypt               1.17 cycles/byte,  2.39 GiB/s
nss                  1.39 cycles/byte,  2.01 GiB/s
aes256ni             0.57 cycles/byte,  4.89 GiB/s
aes256ni-openssl     0.48 cycles/byte,  5.82 GiB/s
aes256ni-imb         0.51 cycles/byte,  5.45 GiB/s
vaes256-avx2         0.33 cycles/byte,  8.45 GiB/s
vaes256-avx512       0.27 cycles/byte, 10.41 GiB/s
vaes256-imb-avx512   0.27 cycles/byte, 10.46 GiB/s
```
