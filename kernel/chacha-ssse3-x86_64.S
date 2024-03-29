/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * ChaCha 256-bit cipher algorithm, x64 SSSE3 functions
 *
 * Copyright (C) 2015 Martin Willi
 */

#include "linkage.h"

.section	.rodata.cst16.ROT8, "a"
.align 16
ROT8:	.octa 0x0e0d0c0f0a09080b0605040702010003
.section	.rodata.cst16.ROT16, "a"
.align 16
ROT16:	.octa 0x0d0c0f0e09080b0a0504070601000302
.section	.rodata.cst16.CTRINC, "a"
.align 16
CTRINC:	.octa 0x00000003000000020000000100000000

.text

/*
 * chacha_permute - permute one block
 *
 * Permute one 64-byte block where the state matrix is in %xmm0-%xmm3.  This
 * function performs matrix operations on four words in parallel, but requires
 * shuffling to rearrange the words after each round.  8/16-bit word rotation is
 * done with the slightly better performing SSSE3 byte shuffling, 7/12-bit word
 * rotation uses traditional shift+OR.
 *
 * The round count is given in %r8d.
 *
 * Clobbers: %r8d, %xmm4-%xmm7
 */
SYM_FUNC_START_LOCAL(chacha_permute)

	movdqa		ROT8(%rip),%xmm4
	movdqa		ROT16(%rip),%xmm5

.Ldoubleround:
	# x0 += x1, x3 = rotl32(x3 ^ x0, 16)
	paddd		%xmm1,%xmm0
	pxor		%xmm0,%xmm3
	pshufb		%xmm5,%xmm3

	# x2 += x3, x1 = rotl32(x1 ^ x2, 12)
	paddd		%xmm3,%xmm2
	pxor		%xmm2,%xmm1
	movdqa		%xmm1,%xmm6
	pslld		$12,%xmm6
	psrld		$20,%xmm1
	por		%xmm6,%xmm1

	# x0 += x1, x3 = rotl32(x3 ^ x0, 8)
	paddd		%xmm1,%xmm0
	pxor		%xmm0,%xmm3
	pshufb		%xmm4,%xmm3

	# x2 += x3, x1 = rotl32(x1 ^ x2, 7)
	paddd		%xmm3,%xmm2
	pxor		%xmm2,%xmm1
	movdqa		%xmm1,%xmm7
	pslld		$7,%xmm7
	psrld		$25,%xmm1
	por		%xmm7,%xmm1

	# x1 = shuffle32(x1, MASK(0, 3, 2, 1))
	pshufd		$0x39,%xmm1,%xmm1
	# x2 = shuffle32(x2, MASK(1, 0, 3, 2))
	pshufd		$0x4e,%xmm2,%xmm2
	# x3 = shuffle32(x3, MASK(2, 1, 0, 3))
	pshufd		$0x93,%xmm3,%xmm3

	# x0 += x1, x3 = rotl32(x3 ^ x0, 16)
	paddd		%xmm1,%xmm0
	pxor		%xmm0,%xmm3
	pshufb		%xmm5,%xmm3

	# x2 += x3, x1 = rotl32(x1 ^ x2, 12)
	paddd		%xmm3,%xmm2
	pxor		%xmm2,%xmm1
	movdqa		%xmm1,%xmm6
	pslld		$12,%xmm6
	psrld		$20,%xmm1
	por		%xmm6,%xmm1

	# x0 += x1, x3 = rotl32(x3 ^ x0, 8)
	paddd		%xmm1,%xmm0
	pxor		%xmm0,%xmm3
	pshufb		%xmm4,%xmm3

	# x2 += x3, x1 = rotl32(x1 ^ x2, 7)
	paddd		%xmm3,%xmm2
	pxor		%xmm2,%xmm1
	movdqa		%xmm1,%xmm7
	pslld		$7,%xmm7
	psrld		$25,%xmm1
	por		%xmm7,%xmm1

	# x1 = shuffle32(x1, MASK(2, 1, 0, 3))
	pshufd		$0x93,%xmm1,%xmm1
	# x2 = shuffle32(x2, MASK(1, 0, 3, 2))
	pshufd		$0x4e,%xmm2,%xmm2
	# x3 = shuffle32(x3, MASK(0, 3, 2, 1))
	pshufd		$0x39,%xmm3,%xmm3

	sub		$2,%r8d
	jnz		.Ldoubleround

	ret
SYM_FUNC_END(chacha_permute)

SYM_FUNC_START(chacha_block_xor_ssse3)
	# %rdi: Input state matrix, s
	# %rsi: up to 1 data block output, o
	# %rdx: up to 1 data block input, i
	# %rcx: input/output length in bytes
	# %r8d: nrounds
	FRAME_BEGIN

	# x0..3 = s0..3
	movdqu		0x00(%rdi),%xmm0
	movdqu		0x10(%rdi),%xmm1
	movdqu		0x20(%rdi),%xmm2
	movdqu		0x30(%rdi),%xmm3
	movdqa		%xmm0,%xmm8
	movdqa		%xmm1,%xmm9
	movdqa		%xmm2,%xmm10
	movdqa		%xmm3,%xmm11

	mov		%rcx,%rax
	call		chacha_permute

	# o0 = i0 ^ (x0 + s0)
	paddd		%xmm8,%xmm0
	cmp		$0x10,%rax
	jl		.Lxorpart
	movdqu		0x00(%rdx),%xmm4
	pxor		%xmm4,%xmm0
	movdqu		%xmm0,0x00(%rsi)
	# o1 = i1 ^ (x1 + s1)
	paddd		%xmm9,%xmm1
	movdqa		%xmm1,%xmm0
	cmp		$0x20,%rax
	jl		.Lxorpart
	movdqu		0x10(%rdx),%xmm0
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x10(%rsi)
	# o2 = i2 ^ (x2 + s2)
	paddd		%xmm10,%xmm2
	movdqa		%xmm2,%xmm0
	cmp		$0x30,%rax
	jl		.Lxorpart
	movdqu		0x20(%rdx),%xmm0
	pxor		%xmm2,%xmm0
	movdqu		%xmm0,0x20(%rsi)
	# o3 = i3 ^ (x3 + s3)
	paddd		%xmm11,%xmm3
	movdqa		%xmm3,%xmm0
	cmp		$0x40,%rax
	jl		.Lxorpart
	movdqu		0x30(%rdx),%xmm0
	pxor		%xmm3,%xmm0
	movdqu		%xmm0,0x30(%rsi)

.Ldone:
	FRAME_END
	ret

.Lxorpart:
	# xor remaining bytes from partial register into output
	mov		%rax,%r9
	and		$0x0f,%r9
	jz		.Ldone
	and		$~0x0f,%rax

	mov		%rsi,%r11

	lea		8(%rsp),%r10
	sub		$0x10,%rsp
	and		$~31,%rsp

	lea		(%rdx,%rax),%rsi
	mov		%rsp,%rdi
	mov		%r9,%rcx
	rep movsb

	pxor		0x00(%rsp),%xmm0
	movdqa		%xmm0,0x00(%rsp)

	mov		%rsp,%rsi
	lea		(%r11,%rax),%rdi
	mov		%r9,%rcx
	rep movsb

	lea		-8(%r10),%rsp
	jmp		.Ldone

SYM_FUNC_END(chacha_block_xor_ssse3)

SYM_FUNC_START(hchacha_block_ssse3)
	# %rdi: Input state matrix, s
	# %rsi: output (8 32-bit words)
	# %edx: nrounds
	FRAME_BEGIN

	movdqu		0x00(%rdi),%xmm0
	movdqu		0x10(%rdi),%xmm1
	movdqu		0x20(%rdi),%xmm2
	movdqu		0x30(%rdi),%xmm3

	mov		%edx,%r8d
	call		chacha_permute

	movdqu		%xmm0,0x00(%rsi)
	movdqu		%xmm3,0x10(%rsi)

	FRAME_END
	ret
SYM_FUNC_END(hchacha_block_ssse3)

SYM_FUNC_START(chacha_4block_xor_ssse3)
	# %rdi: Input state matrix, s
	# %rsi: up to 4 data blocks output, o
	# %rdx: up to 4 data blocks input, i
	# %rcx: input/output length in bytes
	# %r8d: nrounds

	# This function encrypts four consecutive ChaCha blocks by loading the
	# the state matrix in SSE registers four times. As we need some scratch
	# registers, we save the first four registers on the stack. The
	# algorithm performs each operation on the corresponding word of each
	# state matrix, hence requires no word shuffling. For final XORing step
	# we transpose the matrix by interleaving 32- and then 64-bit words,
	# which allows us to do XOR in SSE registers. 8/16-bit word rotation is
	# done with the slightly better performing SSSE3 byte shuffling,
	# 7/12-bit word rotation uses traditional shift+OR.

	lea		8(%rsp),%r10
	sub		$0x80,%rsp
	and		$~63,%rsp
	mov		%rcx,%rax

	# x0..15[0-3] = s0..3[0..3]
	movq		0x00(%rdi),%xmm1
	pshufd		$0x00,%xmm1,%xmm0
	pshufd		$0x55,%xmm1,%xmm1
	movq		0x08(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	movq		0x10(%rdi),%xmm5
	pshufd		$0x00,%xmm5,%xmm4
	pshufd		$0x55,%xmm5,%xmm5
	movq		0x18(%rdi),%xmm7
	pshufd		$0x00,%xmm7,%xmm6
	pshufd		$0x55,%xmm7,%xmm7
	movq		0x20(%rdi),%xmm9
	pshufd		$0x00,%xmm9,%xmm8
	pshufd		$0x55,%xmm9,%xmm9
	movq		0x28(%rdi),%xmm11
	pshufd		$0x00,%xmm11,%xmm10
	pshufd		$0x55,%xmm11,%xmm11
	movq		0x30(%rdi),%xmm13
	pshufd		$0x00,%xmm13,%xmm12
	pshufd		$0x55,%xmm13,%xmm13
	movq		0x38(%rdi),%xmm15
	pshufd		$0x00,%xmm15,%xmm14
	pshufd		$0x55,%xmm15,%xmm15
	# x0..3 on stack
	movdqa		%xmm0,0x00(%rsp)
	movdqa		%xmm1,0x10(%rsp)
	movdqa		%xmm2,0x20(%rsp)
	movdqa		%xmm3,0x30(%rsp)

	movdqa		CTRINC(%rip),%xmm1
	movdqa		ROT8(%rip),%xmm2
	movdqa		ROT16(%rip),%xmm3

	# x12 += counter values 0-3
	paddd		%xmm1,%xmm12

.Ldoubleround4:
	# x0 += x4, x12 = rotl32(x12 ^ x0, 16)
	movdqa		0x00(%rsp),%xmm0
	paddd		%xmm4,%xmm0
	movdqa		%xmm0,0x00(%rsp)
	pxor		%xmm0,%xmm12
	pshufb		%xmm3,%xmm12
	# x1 += x5, x13 = rotl32(x13 ^ x1, 16)
	movdqa		0x10(%rsp),%xmm0
	paddd		%xmm5,%xmm0
	movdqa		%xmm0,0x10(%rsp)
	pxor		%xmm0,%xmm13
	pshufb		%xmm3,%xmm13
	# x2 += x6, x14 = rotl32(x14 ^ x2, 16)
	movdqa		0x20(%rsp),%xmm0
	paddd		%xmm6,%xmm0
	movdqa		%xmm0,0x20(%rsp)
	pxor		%xmm0,%xmm14
	pshufb		%xmm3,%xmm14
	# x3 += x7, x15 = rotl32(x15 ^ x3, 16)
	movdqa		0x30(%rsp),%xmm0
	paddd		%xmm7,%xmm0
	movdqa		%xmm0,0x30(%rsp)
	pxor		%xmm0,%xmm15
	pshufb		%xmm3,%xmm15

	# x8 += x12, x4 = rotl32(x4 ^ x8, 12)
	paddd		%xmm12,%xmm8
	pxor		%xmm8,%xmm4
	movdqa		%xmm4,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm4
	por		%xmm0,%xmm4
	# x9 += x13, x5 = rotl32(x5 ^ x9, 12)
	paddd		%xmm13,%xmm9
	pxor		%xmm9,%xmm5
	movdqa		%xmm5,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm5
	por		%xmm0,%xmm5
	# x10 += x14, x6 = rotl32(x6 ^ x10, 12)
	paddd		%xmm14,%xmm10
	pxor		%xmm10,%xmm6
	movdqa		%xmm6,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm6
	por		%xmm0,%xmm6
	# x11 += x15, x7 = rotl32(x7 ^ x11, 12)
	paddd		%xmm15,%xmm11
	pxor		%xmm11,%xmm7
	movdqa		%xmm7,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm7
	por		%xmm0,%xmm7

	# x0 += x4, x12 = rotl32(x12 ^ x0, 8)
	movdqa		0x00(%rsp),%xmm0
	paddd		%xmm4,%xmm0
	movdqa		%xmm0,0x00(%rsp)
	pxor		%xmm0,%xmm12
	pshufb		%xmm2,%xmm12
	# x1 += x5, x13 = rotl32(x13 ^ x1, 8)
	movdqa		0x10(%rsp),%xmm0
	paddd		%xmm5,%xmm0
	movdqa		%xmm0,0x10(%rsp)
	pxor		%xmm0,%xmm13
	pshufb		%xmm2,%xmm13
	# x2 += x6, x14 = rotl32(x14 ^ x2, 8)
	movdqa		0x20(%rsp),%xmm0
	paddd		%xmm6,%xmm0
	movdqa		%xmm0,0x20(%rsp)
	pxor		%xmm0,%xmm14
	pshufb		%xmm2,%xmm14
	# x3 += x7, x15 = rotl32(x15 ^ x3, 8)
	movdqa		0x30(%rsp),%xmm0
	paddd		%xmm7,%xmm0
	movdqa		%xmm0,0x30(%rsp)
	pxor		%xmm0,%xmm15
	pshufb		%xmm2,%xmm15

	# x8 += x12, x4 = rotl32(x4 ^ x8, 7)
	paddd		%xmm12,%xmm8
	pxor		%xmm8,%xmm4
	movdqa		%xmm4,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm4
	por		%xmm0,%xmm4
	# x9 += x13, x5 = rotl32(x5 ^ x9, 7)
	paddd		%xmm13,%xmm9
	pxor		%xmm9,%xmm5
	movdqa		%xmm5,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm5
	por		%xmm0,%xmm5
	# x10 += x14, x6 = rotl32(x6 ^ x10, 7)
	paddd		%xmm14,%xmm10
	pxor		%xmm10,%xmm6
	movdqa		%xmm6,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm6
	por		%xmm0,%xmm6
	# x11 += x15, x7 = rotl32(x7 ^ x11, 7)
	paddd		%xmm15,%xmm11
	pxor		%xmm11,%xmm7
	movdqa		%xmm7,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm7
	por		%xmm0,%xmm7

	# x0 += x5, x15 = rotl32(x15 ^ x0, 16)
	movdqa		0x00(%rsp),%xmm0
	paddd		%xmm5,%xmm0
	movdqa		%xmm0,0x00(%rsp)
	pxor		%xmm0,%xmm15
	pshufb		%xmm3,%xmm15
	# x1 += x6, x12 = rotl32(x12 ^ x1, 16)
	movdqa		0x10(%rsp),%xmm0
	paddd		%xmm6,%xmm0
	movdqa		%xmm0,0x10(%rsp)
	pxor		%xmm0,%xmm12
	pshufb		%xmm3,%xmm12
	# x2 += x7, x13 = rotl32(x13 ^ x2, 16)
	movdqa		0x20(%rsp),%xmm0
	paddd		%xmm7,%xmm0
	movdqa		%xmm0,0x20(%rsp)
	pxor		%xmm0,%xmm13
	pshufb		%xmm3,%xmm13
	# x3 += x4, x14 = rotl32(x14 ^ x3, 16)
	movdqa		0x30(%rsp),%xmm0
	paddd		%xmm4,%xmm0
	movdqa		%xmm0,0x30(%rsp)
	pxor		%xmm0,%xmm14
	pshufb		%xmm3,%xmm14

	# x10 += x15, x5 = rotl32(x5 ^ x10, 12)
	paddd		%xmm15,%xmm10
	pxor		%xmm10,%xmm5
	movdqa		%xmm5,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm5
	por		%xmm0,%xmm5
	# x11 += x12, x6 = rotl32(x6 ^ x11, 12)
	paddd		%xmm12,%xmm11
	pxor		%xmm11,%xmm6
	movdqa		%xmm6,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm6
	por		%xmm0,%xmm6
	# x8 += x13, x7 = rotl32(x7 ^ x8, 12)
	paddd		%xmm13,%xmm8
	pxor		%xmm8,%xmm7
	movdqa		%xmm7,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm7
	por		%xmm0,%xmm7
	# x9 += x14, x4 = rotl32(x4 ^ x9, 12)
	paddd		%xmm14,%xmm9
	pxor		%xmm9,%xmm4
	movdqa		%xmm4,%xmm0
	pslld		$12,%xmm0
	psrld		$20,%xmm4
	por		%xmm0,%xmm4

	# x0 += x5, x15 = rotl32(x15 ^ x0, 8)
	movdqa		0x00(%rsp),%xmm0
	paddd		%xmm5,%xmm0
	movdqa		%xmm0,0x00(%rsp)
	pxor		%xmm0,%xmm15
	pshufb		%xmm2,%xmm15
	# x1 += x6, x12 = rotl32(x12 ^ x1, 8)
	movdqa		0x10(%rsp),%xmm0
	paddd		%xmm6,%xmm0
	movdqa		%xmm0,0x10(%rsp)
	pxor		%xmm0,%xmm12
	pshufb		%xmm2,%xmm12
	# x2 += x7, x13 = rotl32(x13 ^ x2, 8)
	movdqa		0x20(%rsp),%xmm0
	paddd		%xmm7,%xmm0
	movdqa		%xmm0,0x20(%rsp)
	pxor		%xmm0,%xmm13
	pshufb		%xmm2,%xmm13
	# x3 += x4, x14 = rotl32(x14 ^ x3, 8)
	movdqa		0x30(%rsp),%xmm0
	paddd		%xmm4,%xmm0
	movdqa		%xmm0,0x30(%rsp)
	pxor		%xmm0,%xmm14
	pshufb		%xmm2,%xmm14

	# x10 += x15, x5 = rotl32(x5 ^ x10, 7)
	paddd		%xmm15,%xmm10
	pxor		%xmm10,%xmm5
	movdqa		%xmm5,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm5
	por		%xmm0,%xmm5
	# x11 += x12, x6 = rotl32(x6 ^ x11, 7)
	paddd		%xmm12,%xmm11
	pxor		%xmm11,%xmm6
	movdqa		%xmm6,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm6
	por		%xmm0,%xmm6
	# x8 += x13, x7 = rotl32(x7 ^ x8, 7)
	paddd		%xmm13,%xmm8
	pxor		%xmm8,%xmm7
	movdqa		%xmm7,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm7
	por		%xmm0,%xmm7
	# x9 += x14, x4 = rotl32(x4 ^ x9, 7)
	paddd		%xmm14,%xmm9
	pxor		%xmm9,%xmm4
	movdqa		%xmm4,%xmm0
	pslld		$7,%xmm0
	psrld		$25,%xmm4
	por		%xmm0,%xmm4

	sub		$2,%r8d
	jnz		.Ldoubleround4

	# x0[0-3] += s0[0]
	# x1[0-3] += s0[1]
	movq		0x00(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		0x00(%rsp),%xmm2
	movdqa		%xmm2,0x00(%rsp)
	paddd		0x10(%rsp),%xmm3
	movdqa		%xmm3,0x10(%rsp)
	# x2[0-3] += s0[2]
	# x3[0-3] += s0[3]
	movq		0x08(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		0x20(%rsp),%xmm2
	movdqa		%xmm2,0x20(%rsp)
	paddd		0x30(%rsp),%xmm3
	movdqa		%xmm3,0x30(%rsp)

	# x4[0-3] += s1[0]
	# x5[0-3] += s1[1]
	movq		0x10(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		%xmm2,%xmm4
	paddd		%xmm3,%xmm5
	# x6[0-3] += s1[2]
	# x7[0-3] += s1[3]
	movq		0x18(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		%xmm2,%xmm6
	paddd		%xmm3,%xmm7

	# x8[0-3] += s2[0]
	# x9[0-3] += s2[1]
	movq		0x20(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		%xmm2,%xmm8
	paddd		%xmm3,%xmm9
	# x10[0-3] += s2[2]
	# x11[0-3] += s2[3]
	movq		0x28(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		%xmm2,%xmm10
	paddd		%xmm3,%xmm11

	# x12[0-3] += s3[0]
	# x13[0-3] += s3[1]
	movq		0x30(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		%xmm2,%xmm12
	paddd		%xmm3,%xmm13
	# x14[0-3] += s3[2]
	# x15[0-3] += s3[3]
	movq		0x38(%rdi),%xmm3
	pshufd		$0x00,%xmm3,%xmm2
	pshufd		$0x55,%xmm3,%xmm3
	paddd		%xmm2,%xmm14
	paddd		%xmm3,%xmm15

	# x12 += counter values 0-3
	paddd		%xmm1,%xmm12

	# interleave 32-bit words in state n, n+1
	movdqa		0x00(%rsp),%xmm0
	movdqa		0x10(%rsp),%xmm1
	movdqa		%xmm0,%xmm2
	punpckldq	%xmm1,%xmm2
	punpckhdq	%xmm1,%xmm0
	movdqa		%xmm2,0x00(%rsp)
	movdqa		%xmm0,0x10(%rsp)
	movdqa		0x20(%rsp),%xmm0
	movdqa		0x30(%rsp),%xmm1
	movdqa		%xmm0,%xmm2
	punpckldq	%xmm1,%xmm2
	punpckhdq	%xmm1,%xmm0
	movdqa		%xmm2,0x20(%rsp)
	movdqa		%xmm0,0x30(%rsp)
	movdqa		%xmm4,%xmm0
	punpckldq	%xmm5,%xmm4
	punpckhdq	%xmm5,%xmm0
	movdqa		%xmm0,%xmm5
	movdqa		%xmm6,%xmm0
	punpckldq	%xmm7,%xmm6
	punpckhdq	%xmm7,%xmm0
	movdqa		%xmm0,%xmm7
	movdqa		%xmm8,%xmm0
	punpckldq	%xmm9,%xmm8
	punpckhdq	%xmm9,%xmm0
	movdqa		%xmm0,%xmm9
	movdqa		%xmm10,%xmm0
	punpckldq	%xmm11,%xmm10
	punpckhdq	%xmm11,%xmm0
	movdqa		%xmm0,%xmm11
	movdqa		%xmm12,%xmm0
	punpckldq	%xmm13,%xmm12
	punpckhdq	%xmm13,%xmm0
	movdqa		%xmm0,%xmm13
	movdqa		%xmm14,%xmm0
	punpckldq	%xmm15,%xmm14
	punpckhdq	%xmm15,%xmm0
	movdqa		%xmm0,%xmm15

	# interleave 64-bit words in state n, n+2
	movdqa		0x00(%rsp),%xmm0
	movdqa		0x20(%rsp),%xmm1
	movdqa		%xmm0,%xmm2
	punpcklqdq	%xmm1,%xmm2
	punpckhqdq	%xmm1,%xmm0
	movdqa		%xmm2,0x00(%rsp)
	movdqa		%xmm0,0x20(%rsp)
	movdqa		0x10(%rsp),%xmm0
	movdqa		0x30(%rsp),%xmm1
	movdqa		%xmm0,%xmm2
	punpcklqdq	%xmm1,%xmm2
	punpckhqdq	%xmm1,%xmm0
	movdqa		%xmm2,0x10(%rsp)
	movdqa		%xmm0,0x30(%rsp)
	movdqa		%xmm4,%xmm0
	punpcklqdq	%xmm6,%xmm4
	punpckhqdq	%xmm6,%xmm0
	movdqa		%xmm0,%xmm6
	movdqa		%xmm5,%xmm0
	punpcklqdq	%xmm7,%xmm5
	punpckhqdq	%xmm7,%xmm0
	movdqa		%xmm0,%xmm7
	movdqa		%xmm8,%xmm0
	punpcklqdq	%xmm10,%xmm8
	punpckhqdq	%xmm10,%xmm0
	movdqa		%xmm0,%xmm10
	movdqa		%xmm9,%xmm0
	punpcklqdq	%xmm11,%xmm9
	punpckhqdq	%xmm11,%xmm0
	movdqa		%xmm0,%xmm11
	movdqa		%xmm12,%xmm0
	punpcklqdq	%xmm14,%xmm12
	punpckhqdq	%xmm14,%xmm0
	movdqa		%xmm0,%xmm14
	movdqa		%xmm13,%xmm0
	punpcklqdq	%xmm15,%xmm13
	punpckhqdq	%xmm15,%xmm0
	movdqa		%xmm0,%xmm15

	# xor with corresponding input, write to output
	movdqa		0x00(%rsp),%xmm0
	cmp		$0x10,%rax
	jl		.Lxorpart4
	movdqu		0x00(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x00(%rsi)

	movdqu		%xmm4,%xmm0
	cmp		$0x20,%rax
	jl		.Lxorpart4
	movdqu		0x10(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x10(%rsi)

	movdqu		%xmm8,%xmm0
	cmp		$0x30,%rax
	jl		.Lxorpart4
	movdqu		0x20(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x20(%rsi)

	movdqu		%xmm12,%xmm0
	cmp		$0x40,%rax
	jl		.Lxorpart4
	movdqu		0x30(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x30(%rsi)

	movdqa		0x20(%rsp),%xmm0
	cmp		$0x50,%rax
	jl		.Lxorpart4
	movdqu		0x40(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x40(%rsi)

	movdqu		%xmm6,%xmm0
	cmp		$0x60,%rax
	jl		.Lxorpart4
	movdqu		0x50(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x50(%rsi)

	movdqu		%xmm10,%xmm0
	cmp		$0x70,%rax
	jl		.Lxorpart4
	movdqu		0x60(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x60(%rsi)

	movdqu		%xmm14,%xmm0
	cmp		$0x80,%rax
	jl		.Lxorpart4
	movdqu		0x70(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x70(%rsi)

	movdqa		0x10(%rsp),%xmm0
	cmp		$0x90,%rax
	jl		.Lxorpart4
	movdqu		0x80(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x80(%rsi)

	movdqu		%xmm5,%xmm0
	cmp		$0xa0,%rax
	jl		.Lxorpart4
	movdqu		0x90(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0x90(%rsi)

	movdqu		%xmm9,%xmm0
	cmp		$0xb0,%rax
	jl		.Lxorpart4
	movdqu		0xa0(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0xa0(%rsi)

	movdqu		%xmm13,%xmm0
	cmp		$0xc0,%rax
	jl		.Lxorpart4
	movdqu		0xb0(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0xb0(%rsi)

	movdqa		0x30(%rsp),%xmm0
	cmp		$0xd0,%rax
	jl		.Lxorpart4
	movdqu		0xc0(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0xc0(%rsi)

	movdqu		%xmm7,%xmm0
	cmp		$0xe0,%rax
	jl		.Lxorpart4
	movdqu		0xd0(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0xd0(%rsi)

	movdqu		%xmm11,%xmm0
	cmp		$0xf0,%rax
	jl		.Lxorpart4
	movdqu		0xe0(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0xe0(%rsi)

	movdqu		%xmm15,%xmm0
	cmp		$0x100,%rax
	jl		.Lxorpart4
	movdqu		0xf0(%rdx),%xmm1
	pxor		%xmm1,%xmm0
	movdqu		%xmm0,0xf0(%rsi)

.Ldone4:
	lea		-8(%r10),%rsp
	ret

.Lxorpart4:
	# xor remaining bytes from partial register into output
	mov		%rax,%r9
	and		$0x0f,%r9
	jz		.Ldone4
	and		$~0x0f,%rax

	mov		%rsi,%r11

	lea		(%rdx,%rax),%rsi
	mov		%rsp,%rdi
	mov		%r9,%rcx
	rep movsb

	pxor		0x00(%rsp),%xmm0
	movdqa		%xmm0,0x00(%rsp)

	mov		%rsp,%rsi
	lea		(%r11,%rax),%rdi
	mov		%r9,%rcx
	rep movsb

	jmp		.Ldone4

SYM_FUNC_END(chacha_4block_xor_ssse3)
