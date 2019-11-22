#
# This dockefile is intended for automatic regression testing of the Patmos toolchain.
# 
# First, it will setup a fresh ubuntu image with all the required tools.
# It will then copy the patmos-misc folder into the container, where it will then run the regression test in full.
# The result of running the container is a short message of either success or failure.
# For more detailed error message, the container should be run in interactive mode and inspected after 
# running the regression test manually. 
#
FROM ubuntu:latest

# Start by getting gnupg, such that we can follow the handbook setup instructions.
RUN apt-get update && apt-get install --assume-yes gnupg ca-certificates

# Instruction from the patmos handbook
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
RUN apt-get update

# The following two lines are not usually needed for setup, but 'tzdata' must be installed this way
# when using docker, since otherwise it will interactively ask for configuration data 
# as part of the installation (which will render the docker build hanging forever).
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install tzdata

# Install all required tools.
RUN apt-get install --assume-yes git default-jdk gitk cmake make g++ texinfo flex bison subversion libelf-dev graphviz libboost-dev libboost-program-options-dev ruby-full liblpsolve55-dev python zlib1g-dev gtkwave gtkterm scala sbt

WORKDIR ~

# Set the path to point to the Patmos toolchain binaries
ENV PATH="$PATH:/~/t-crest/local/bin"

# Setup directory structure for regression test.
RUN mkdir t-crest
WORKDIR t-crest
COPY . misc/

# Ensure the regression test scripts have permission to execute
RUN ["chmod", "+x", "./misc/regtest.sh"]
RUN ["chmod", "+x", "./misc/regtest-init.sh"]
RUN ["chmod", "+x", "./misc/build.sh"]

# Upon non-interactive container run, execute the regression test.
CMD ["/bin/bash", "-c", "./misc/regtest-init.sh"]


