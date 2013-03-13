	.file	"/tmp/hello-KySPwH.bc"
	.text
	.globl	main
	.type	main,@function
	.fstart	main, .Ltmp0-main, 4         # @main
main:
.LBB0_0:                                     # %entry
	       sres	3                    # encoding: [0x03,0x00,0x00,0x03]
	       sub	$r29 = $r29, 24      # encoding: [0x00,0x7b,0xd0,0x18]
	       sws	[2] = $r31           # encoding: [0x02,0xc0,0x0f,0x82]
	       sws	[1] = $r30           # encoding: [0x02,0xc0,0x0f,0x01]
	       mfs	$r9 = $s0            # encoding: [0x02,0x52,0x00,0x30]
	       sws	[0] = $r9            # encoding: [0x02,0xc0,0x04,0x80]
	       li	$r30 = main          # encoding: [0x87,0xfc,0x00,0x00,A,A,A,A]
               #   fixup A - offset: 0, value: main, kind: FK_Patmos_abs_ALUl
	       swc	[$r29 + 2] = $r0     # encoding: [0x02,0xc5,0xd0,0x02]
	       swc	[$r29 + 3] = $r3     # encoding: [0x02,0xc5,0xd1,0x83]
	       swc	[$r29 + 4] = $r4     # encoding: [0x02,0xc5,0xd2,0x04]
	       li	$r1 = 20             # encoding: [0x00,0x02,0x00,0x14]
	       swc	[$r29 + 5] = $r1     # encoding: [0x02,0xc5,0xd0,0x85]
	       li	$r1 = 1              # encoding: [0x00,0x02,0x00,0x01]
	       lwc	$r2 = [$r29 + 3]     # encoding: [0x02,0x85,0xd1,0x03]
	       nop	                     # encoding: [0x00,0x40,0x00,0x00]
	       cmplt	$p1 = $r2, $r1       # encoding: [0x02,0x02,0x20,0xb2]
	(!$p1) call	__divsi3             # encoding: [0x4e,0b00AAAAAA,A,A]
               #   fixup A - offset: 0, value: __divsi3, kind: FK_Patmos_abs_CFLb
	(!$p1) lwc	$r3 = [$r29 + 5]     # encoding: [0x4a,0x87,0xd1,0x05]
	(!$p1) lwc	$r4 = [$r29 + 3]     # encoding: [0x4a,0x89,0xd1,0x03]
	(!$p1) sens	3                    # encoding: [0x4b,0x40,0x00,0x03]
	(!$p1) swc	[$r29 + 5] = $r1     # encoding: [0x4a,0xc5,0xd0,0x85]
	       lwc	$r1 = [$r29 + 5]     # encoding: [0x02,0x83,0xd1,0x05]
	       nop	                     # encoding: [0x00,0x40,0x00,0x00]
	       swc	[$r29 + 1] = $r1     # encoding: [0x02,0xc5,0xd0,0x81]
	       call	printf               # encoding: [0x06,0b00AAAAAA,A,A]
               #   fixup A - offset: 0, value: printf, kind: FK_Patmos_abs_CFLb
	       li	$r1 = .L.str         # encoding: [0x87,0xc2,0x00,0x00,A,A,A,A]
               #   fixup A - offset: 0, value: .L.str, kind: FK_Patmos_abs_ALUl
	       swc	[$r29] = $r1         # encoding: [0x02,0xc5,0xd0,0x80]
	       sens	3                    # encoding: [0x03,0x40,0x00,0x03]
	       mov	$r1 = $r0            # encoding: [0x00,0x02,0x00,0x00]
	       lws	$r31 = [2]           # encoding: [0x02,0xbe,0x00,0x02]
	       lws	$r30 = [1]           # encoding: [0x02,0xbc,0x00,0x01]
	       lws	$r9 = [0]            # encoding: [0x02,0x92,0x00,0x00]
	       sfree	3                    # encoding: [0x03,0x80,0x00,0x03]
	       ret	$r30, $r31           # encoding: [0x07,0x81,0xef,0x80]
	       mts	$s0 = $r9            # encoding: [0x02,0x40,0x90,0x20]
	       add	$r29 = $r29, 24      # encoding: [0x00,0x3b,0xd0,0x18]
.Ltmp0:
.Ltmp1:
	.size	main, .Ltmp1-main

	.type	.L.str,@object               # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	 "Hello World: %d\n"
	.size	.L.str, 17


