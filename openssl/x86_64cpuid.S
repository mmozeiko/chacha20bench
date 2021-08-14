
.comm	OPENSSL_ia32cap_P,16,4

.text	

.globl	OPENSSL_ia32_cpuid
//.type	OPENSSL_ia32_cpuid,@function
.align	16
OPENSSL_ia32_cpuid:
.cfi_startproc	
.byte	243,15,30,250
	movq	%rbx,%r8
.cfi_register	%rbx,%r8

	xorl	%eax,%eax
	movq	%rax,8(%rdi)
	cpuid
	movl	%eax,%r11d

	xorl	%eax,%eax
	cmpl	$0x756e6547,%ebx
	setne	%al
	movl	%eax,%r9d
	cmpl	$0x49656e69,%edx
	setne	%al
	orl	%eax,%r9d
	cmpl	$0x6c65746e,%ecx
	setne	%al
	orl	%eax,%r9d
	jz	.Lintel

	cmpl	$0x68747541,%ebx
	setne	%al
	movl	%eax,%r10d
	cmpl	$0x69746E65,%edx
	setne	%al
	orl	%eax,%r10d
	cmpl	$0x444D4163,%ecx
	setne	%al
	orl	%eax,%r10d
	jnz	.Lintel


	movl	$0x80000000,%eax
	cpuid
	cmpl	$0x80000001,%eax
	jb	.Lintel
	movl	%eax,%r10d
	movl	$0x80000001,%eax
	cpuid
	orl	%ecx,%r9d
	andl	$0x00000801,%r9d

	cmpl	$0x80000008,%r10d
	jb	.Lintel

	movl	$0x80000008,%eax
	cpuid
	movzbq	%cl,%r10
	incq	%r10

	movl	$1,%eax
	cpuid
	btl	$28,%edx
	jnc	.Lgeneric
	shrl	$16,%ebx
	cmpb	%r10b,%bl
	ja	.Lgeneric
	andl	$0xefffffff,%edx
	jmp	.Lgeneric

.Lintel:
	cmpl	$4,%r11d
	movl	$-1,%r10d
	jb	.Lnocacheinfo

	movl	$4,%eax
	movl	$0,%ecx
	cpuid
	movl	%eax,%r10d
	shrl	$14,%r10d
	andl	$0xfff,%r10d

.Lnocacheinfo:
	movl	$1,%eax
	cpuid
	movd	%eax,%xmm0
	andl	$0xbfefffff,%edx
	cmpl	$0,%r9d
	jne	.Lnotintel
	orl	$0x40000000,%edx
	andb	$15,%ah
	cmpb	$15,%ah
	jne	.LnotP4
	orl	$0x00100000,%edx
.LnotP4:
	cmpb	$6,%ah
	jne	.Lnotintel
	andl	$0x0fff0ff0,%eax
	cmpl	$0x00050670,%eax
	je	.Lknights
	cmpl	$0x00080650,%eax
	jne	.Lnotintel
.Lknights:
	andl	$0xfbffffff,%ecx

.Lnotintel:
	btl	$28,%edx
	jnc	.Lgeneric
	andl	$0xefffffff,%edx
	cmpl	$0,%r10d
	je	.Lgeneric

	orl	$0x10000000,%edx
	shrl	$16,%ebx
	cmpb	$1,%bl
	ja	.Lgeneric
	andl	$0xefffffff,%edx
.Lgeneric:
	andl	$0x00000800,%r9d
	andl	$0xfffff7ff,%ecx
	orl	%ecx,%r9d

	movl	%edx,%r10d

	cmpl	$7,%r11d
	jb	.Lno_extended_info
	movl	$7,%eax
	xorl	%ecx,%ecx
	cpuid
	btl	$26,%r9d
	jc	.Lnotknights
	andl	$0xfff7ffff,%ebx
.Lnotknights:
	movd	%xmm0,%eax
	andl	$0x0fff0ff0,%eax
	cmpl	$0x00050650,%eax
	jne	.Lnotskylakex
	andl	$0xfffeffff,%ebx

.Lnotskylakex:
	movl	%ebx,8(%rdi)
	movl	%ecx,12(%rdi)
.Lno_extended_info:

	btl	$27,%r9d
	jnc	.Lclear_avx
	xorl	%ecx,%ecx
.byte	0x0f,0x01,0xd0
	andl	$0xe6,%eax
	cmpl	$0xe6,%eax
	je	.Ldone
	andl	$0x3fdeffff,8(%rdi)




	andl	$6,%eax
	cmpl	$6,%eax
	je	.Ldone
.Lclear_avx:
	movl	$0xefffe7ff,%eax
	andl	%eax,%r9d
	movl	$0x3fdeffdf,%eax
	andl	%eax,8(%rdi)
.Ldone:
	shlq	$32,%r9
	movl	%r10d,%eax
	movq	%r8,%rbx
.cfi_restore	%rbx
	orq	%r9,%rax
	.byte	0xf3,0xc3
.cfi_endproc	
//.size	OPENSSL_ia32_cpuid,.-OPENSSL_ia32_cpuid
