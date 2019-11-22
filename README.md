patmos-misc
===========

Config files, scripts, and other stuff for Patmos

## Regression testing

We use [Travis CI](https://travis-ci.org/t-crest/patmos-misc/builds/611244101?utm_source=github_status&utm_medium=notification) to test the most important parts of the patmos toolchain, and ensure that they are working as expected.
Regression tests are scheduled to run on Travis once a day, and are refered to as 'the nightly test'.

Travis runs the regression test using a docker image built from the `dockerfile` in this repository.
The regression test can also be run locally using the same docker setup.
This is useful when investigating why the nightly test failed, as Travis cannot provide detailed error messages.

To run a regression test locally, docker needs to be installed on the machine. First you build the docker image that will be used to run the test:

```docker build --no-cache -t t-crest/regression .```

You can then have the image run the test automatically and report the result (this can take multiple hours):

```docker run t-crest/regression```

The above command will not produce detailed error messages (in case of an error). To investigate problems with the test, it is best to interactively run the docker container and manually run the test. First, start the container in interactive mode:

```docker run -it t-crest/regression bash```

This will start the container in the working directory. To run the regression test you simply:

```./misc/regtest-init.sh```

When the regression test finishes, two files will have been produced:

1. `build-log.txt`: A build log from all the repositories built before running the tests. If the issue is with the build, this is where you have to look.
2. `result.txt`: A log containing all test results. If building succeeds, the test might still fail, and this is where all the test results are output.

The regression test can also be run directly on your machine using `regtest-init.sh`, however, this requires the working
directory to be the parent directory of the patmos-misc repository.

#### TODO

To be able to successfully run the docker-based regression test, the git 'origin' remote repository must point to patmos-misc using the https link [https://github.com/t-crest/patmos-misc.git](https://github.com/t-crest/patmos-misc.git).
This is because the regression test will use it to clone other repositories, and if the origin points to a non-t-crest repository, or points using ssh, the docker container wouldn't be able to download the right repositories. 
This should be fixed in the future.




