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
	         sws	[3] = $r9            # 4-byte Folded Spill
	         sws	[4] = $r26           # 4-byte Folded Spill
	         li	$r1 = _0
	         lwc	$r1 = [$r1]              # x = _0
	         li	$r3 = _1
	         lwc	$r3 = [$r3]
	         li	$r2 = -1                     # i = -1
	         cmpeq	$p1 = $r3, 0
	         pand	$p3 =  $p0,  $p1
	         pand	$p2 =  $p0, !$p1
	  ( $p2) li	$r3 = 99                     #l1: r3 = iMax
	  ( $p2) mov	$r5 = $r0                #l1: i_2 = 0, equivalent to i
	  ( $p2) li	$r4 = _2                     #l1: r4 = &_2
	         pmov	$p4 =  $p2               #l1: whether to execute the loop
.LBB0_1:                                     # %for.cond
                                             # =>This Inner Loop Header: Depth=1
	  ( $p4) add	$r2 = $r2, 1             # i++
	  ( $p4) cmplt	$p1 = $r3, $r2           #l1: 99<i <=> !(i<100)
	         pand	$p5 =  $p4, !$p1         #l1: p4 && i<100
	  ( $p5) lwc	$r6 = [$r4]              #l1: load _2
	  ( $p4) pmov	$p4 = !$p1               #l1: p4 = i<100
	  ( $p5) add	$r6 = $r5, $r6           #l1: i_2 + _2
	  ( $p4) br	.LBB0_1                      #l1: loop if i<100 
	  ( $p5) add	$r1 = $r1, $r6           #l1: x += i + _2 (executes before branch)
	  ( $p5) add	$r5 = $r5, 1             #l1: i_2++       (executes before branch)
# BB#2:
	  ( $p3) mov	$r5 = $r0                #l2: i_2 = 0, equivalent to i
	  ( $p3) li	$r4 = _3                     #l2: r4 = &_3
	  ( $p3) li	$r3 = 299                    #l2: e3 = iMax
	         pmov	$p4 =  $p3               #l2: whether to execute the loop
.LBB0_3:                                     # %for.cond2
                                             # =>This Inner Loop Header: Depth=1
	  ( $p4) add	$r2 = $r2, 1             #l2: i++
	  ( $p4) cmplt	$p1 = $r3, $r2           #l2: 299<i <=> !(i<300)
	         pand	$p5 =  $p4, !$p1         #l2: p4 && i<300
	  ( $p5) lwc	$r6 = [$r4]              #l2: load _3
	  ( $p4) pmov	$p4 = !$p1               #l2: p4 = i<300
	  ( $p5) sub	$r6 = $r5, $r6           #l2: i_2 - _3
	  ( $p4) br	.LBB0_3                      #l2: loop if i<300
	  ( $p5) add	$r1 = $r1, $r6           #l2: x += i - _3 (executes before branch)
	  ( $p5) add	$r5 = $r5, 1             #l2: i_2++       (executes before branch)
# BB#4:                                      # %if.end
	         lws	$r9 = [3]            # 4-byte Folded Reload
	         ret	
	         lws	$r26 = [4]           # 4-byte Folded Reload
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


