# Best Practice for Caching of Single-Path Code

This folder contains information and scripts to run the evaluation experiments
for the paper "Best Practice for Caching of Single-Path Code",
submitted to WCET 2017.

## Prerequisites: T-CREST

We use the open-source platform T-CREST for our experiments. Therefore, you
need all T-CREST tools installed. A brief installation instruction can be found
at the [Patmos repository](https://github.com/t-crest/patmos).

We also provide a [VM with Ubuntu](http://patmos.compute.dtu.dk/)
where all needed packages are installed. However, that VM is used in teaching
and does not contain the latest version of T-CREST. Therefore, you need
to reinstall T-CREST there with:

    rm -rf t-crest
    mkdir ~/t-crest
    cd ~/t-crest
    git clone https://github.com/t-crest/patmos-misc.git misc
    ./misc/build.sh

## The Benchmarks

The benchmarks are executed in folder:

    t-crest/misc/experiments/cache_prefetch_lock/wcet2017

A simple `make` will download the
[TACLe Benchmarks](https://github.com/tacle/tacle-bench)
and compile and run most of them. This will take several hours.
Therefore, for first experiments restrict the number of benchmarks
by setting `ALLAPPS` in the `Makefile` to a few programs.

### make targets

`make` will build and run everything.

`make eval` ....

## Further Remarks

Do we keep this?

specify not inlining in benchmark main like:

    void foo_main( void ) __attribute__ ((noinline));
    void foo_main( void ) {
    ...
    }
