This file is intended to automatically check whether a regression test has succeeded or failed.
It should be used with the LLVM FileCheck utility to ensure that the regression test output
reports correct builds and no failing tests.

In FileCheck lines starting with "; CHECK" are used for the checking, while all other lines are ignored.
Therefore, this message can be seen as comments. 

; CHECK-LABEL: Running Patmos benchmark test
; CHECK: Running tests...
; CHECK-NEXT: Test project /home/[[USERNAME:[^/]*]]/t-crest-test/patmos/simulator/build
; CHECK: 100% tests passed, 0 tests failed out of {{[0-9]*}}

; CHECK-LABEL: Testing LLVM Patmos Target
; CHECK: -- Testing: [[PATMOS_TESTS:[0-9]+]] of {{[0-9]*}} tests, {{[0-9]*}} threads --
; CHECK: Expected Passes	: [[PATMOS_TESTS]]

; CHECK-LABEL: Running benchmark
; CHECK: Running tests
; CHECK-NEXT: Test project /home/[[USERNAME]]/t-crest-test/bench/build
; CHECK: 100% tests passed, 0 tests failed out of {{[0-9]*}}
