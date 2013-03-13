; ModuleID = 'hello.c'
target datalayout = 
 "E-S32-p:32:32:32-i8:8:8-i16:16:16-i32:32:32-i64:32:32-f64:32:32-a0:0:32-s0:32:32-v64:32:32-v128:32:32-n32"
target triple = "patmos-unknown-unknown-elf"

@.str = private unnamed_addr constant [17 x i8] 
               c"Hello World: %d\0A\00", align 1

define i32 @main(i32 %argc, i8** %argv) nounwind {
entry:
  %retval = alloca i32, align 4
  %argc.addr = alloca i32, align 4
  %argv.addr = alloca i8**, align 4
  %i = alloca i32, align 4
  store i32 0, i32* %retval
  store i32 %argc, i32* %argc.addr, align 4
  store i8** %argv, i8*** %argv.addr, align 4
  store i32 20, i32* %i, align 4
  %0 = load i32* %argc.addr, align 4
  %cmp = icmp sgt i32 %0, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                    ; preds = %entry
  %1 = load i32* %i, align 4
  %2 = load i32* %argc.addr, align 4
  %div = sdiv i32 %1, %2
  store i32 %div, i32* %i, align 4
  br label %if.end

if.end:                                     ; preds = %if.then, %entry
  %3 = load i32* %i, align 4
  %call = call i32 (i8*, ...)* 
     @printf(i8* getelementptr inbounds ([17 x i8]* @.str, i32 0, i32 0), i32 %3)
  ret i32 0
}

declare i32 @printf(i8*, ...)
