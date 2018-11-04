	.file	"main.bc"
	.text
	.globl	init_func
	.align	16
	.type	init_func,@function
	.fstart	init_func, .Ltmp0-init_func, 16
init_func:                                   # @init_func
# BB#0:                                      # %entry
	         sres	8
	         mfs	$r9 = $s0
	         sws	[1] = $r9            # 4-byte Folded Spill
	         sws	[2] = $r26           # 4-byte Folded Spill
	         li	$r1 = _0
	         lwc	$r1 = [$r1]
	         li	$r2 = _1
	         lwc	$r2 = [$r2]
	         nop	
	         cmpeq	$p1 = $r2, 0
	{        pand	$p2 =  $p0, !$p1 
			 pand	$p3 =  $p0,  $p1 }
	  ( $p2) li	$r2 = _2
	  ( $p2) lwc	$r2 = [$r2]
	  ( $p3) li	$r2 = _3 
	  ( $p3) lwc	$r2 = [$r2]
	  ( $p2) add	$r1 = $r1, $r2       # No point in bundling with previous because of the next instruction needing a nop before it
	  ( $p3) sub	$r1 = $r1, $r2 
	         lws	$r9 = [1]            # 4-byte Folded Reload
	         ret	
	         lws	$r26 = [2]           # 4-byte Folded Reload
	         mts	$s0 = $r9
	         sfree	8
.Ltmp0:
.Ltmp1:
	.size	init_func, .Ltmp1-init_func

	.globl	main
	.align	16
	.type	main,@function
	.fstart	main, .Ltmp2-main, 16
main:                                        # @main
# BB#0:                                      # %entry
	         sres	8
	         mfs	$r9 = $s8
	         sws	[1] = $r9            # 4-byte Folded Spill
	         mfs	$r9 = $s7
	         call	init_func
	         nop	
	         sub	$r31 = $r31, 8
	         sws	[0] = $r9            # 4-byte Folded Spill
	         sens	8
	         swc	[$r31 + 1] = $r1
	         li	$r1 = .L.str
	         swc	[$r31] = $r1
	         callnd	printf
	         sens	8
	         lws	$r9 = [1]            # 4-byte Folded Reload
	         nop	
	         mts	$s8 = $r9
	         lws	$r9 = [0]            # 4-byte Folded Reload
	         nop	
	         mts	$s7 = $r9
	         nop	
	         ret	
	         mov	$r1 = $r0
	         add	$r31 = $r31, 8
	         sfree	8
.Ltmp2:
.Ltmp3:
	.size	main, .Ltmp3-main

	.type	_0,@object                   # @_0
	.bss
	.globl	_0
	.align	4
_0:
	.word	0                            # 0x0
	.size	_0, 4

	.type	_1,@object                   # @_1
	.data
	.globl	_1
	.align	4
_1:
	.word	1                            # 0x1
	.size	_1, 4

	.type	_2,@object                   # @_2
	.globl	_2
	.align	4
_2:
	.word	2                            # 0x2
	.size	_2, 4

	.type	_3,@object                   # @_3
	.globl	_3
	.align	4
_3:
	.word	3                            # 0x3
	.size	_3, 4

	.type	.L.str,@object               # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"%d\n"
	.size	.L.str, 4

