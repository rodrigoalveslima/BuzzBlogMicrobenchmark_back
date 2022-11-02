# Copyright (C) 2022 Georgia Tech Center for Experimental Research in Computer
# Systems

# Define base configuration.
FROM ubuntu:20.04
MAINTAINER ral@gatech.edu
WORKDIR /opt/BuzzBlog/account

# Thrift server host.
ENV host null
# Thrift server port number.
ENV port null

# Install software dependencies.
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-utils \
    automake \
    bison \
    flex \
    g++ \
    git \
    gnupg2 \
    libboost-all-dev \
    libevent-dev \
    libspdlog-dev \
    libssl-dev \
    libtool \
    lsb-core \
    make \
    pkg-config \
    wget \
    unzip

# Install Thrift 0.13.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libthrift-0.13.0=0.13.0-2build2 \
  libthrift-dev=0.13.0-2build2

# Install libyaml 0.6.2.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libyaml-cpp0.6=0.6.2-4ubuntu1 \
  libyaml-cpp-dev=0.6.2-4ubuntu1

# Copy cxxopts 2.2.1.
RUN cd /tmp \
  && wget https://github.com/jarro2783/cxxopts/archive/v2.2.1.zip \
  && unzip v2.2.1.zip \
  && cp cxxopts-2.2.1/include/cxxopts.hpp /usr/local/include

# Copy cppbench 1.0.
RUN cd /tmp \
  && wget https://github.com/rodrigoalveslima/cppbench/archive/v1.0.zip \
  && unzip v1.0.zip \
  && cp cppbench-1.0/include/cppbench.h /usr/local/include

# Copy service client libraries.
COPY include include

# Copy source code.
COPY src src

# Create `logs` directory.
RUN mkdir logs

# Create directory for `backend.yml` file.
RUN mkdir -p /etc/opt/BuzzBlog

# Compile source code.
RUN mkdir bin && \
    g++ -o bin/account_client src/account_client.cpp \
    include/buzzblog/gen/buzzblog_types.cpp \
    include/buzzblog/gen/buzzblog_constants.cpp \
    include/buzzblog/gen/TAccountService.cpp \
    include/buzzblog/gen/TFollowService.cpp \
    include/buzzblog/gen/TLikeService.cpp \
    include/buzzblog/gen/TPostService.cpp \
    include/buzzblog/gen/TUniquepairService.cpp \
    include/buzzblog/gen/TTrendingService.cpp \
    include/buzzblog/gen/TWordfilterService.cpp \
    -std=c++2a -lthrift -lyaml-cpp -lpthread \
    -I/opt/BuzzBlog/account/include \
    -I/usr/local/include

# Start the client.
CMD ["/bin/bash", "-c", "bin/account_client --host $host --port $port"]
