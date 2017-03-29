# Caching for Single Path Code

This README shall describe the experiments for the WCET 2017
paper on caching in Patmos for single-path code.

specify not inlining in benchmark main like:

    void foo_main( void ) __attribute__ ((noinline));
    void foo_main( void ) {
    ...
    }
