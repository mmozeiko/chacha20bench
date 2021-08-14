#define ASM_NL ;
#define SYM_T_NONE			STT_NOTYPE
#define SYM_A_ALIGN			.align 4
#define SYM_L_GLOBAL(name)	.globl name
#define SYM_L_LOCAL(name)	/* nothing */
#define SYM_T_FUNC			STT_FUNC

#ifndef SYM_ENTRY
#define SYM_ENTRY(name, linkage, align...)	\
	linkage(name) ASM_NL					\
	align ASM_NL							\
	name:
#endif

#define SYM_START(name, linkage, align...)	\
	SYM_ENTRY(name, linkage, align)

#define SYM_FUNC_START(name)				\
	SYM_START(name, SYM_L_GLOBAL, SYM_A_ALIGN)

#define SYM_FUNC_START_LOCAL(name)			\
	SYM_START(name, SYM_L_LOCAL, SYM_A_ALIGN)

#define SYM_FUNC_END(name)
#define FRAME_BEGIN
#define FRAME_END
