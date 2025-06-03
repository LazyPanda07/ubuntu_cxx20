ARG CMAKE_VERSION=4.0.2

FROM ubuntu:24.04 as cmake-build

ENV DEBIAN_FRONTEND=noninteractive

ARG CMAKE_VERSION

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN curl -LO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
RUN tar -xvzf cmake-${CMAKE_VERSION}.tar.gz
RUN cd cmake-${CMAKE_VERSION} && ./bootstrap --prefix=/opt/cmake-${CMAKE_VERSION} && make -j $(nproc) && make install

FROM ubuntu:24.04 as libuuid-build

ENV DEBIAN_FRONTEND=noninteractive

ENV CC=/usr/bin/aarch64-linux-gnu-gcc
ENV CXX=/usr/bin/aarch64-linux-gnu-g++

RUN apt update
RUN apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu git zip unzip wget sudo make
RUN apt install -y autoconf autopoint automake gettext flex bison libtool

WORKDIR /tmp

RUN git clone https://github.com/util-linux/util-linux.git
RUN cd util-linux && ./autogen.sh && ./configure --host=aarch64-linux-gnu --prefix=/opt --disable-all-programs --enable-libuuid && make && make install

FROM ubuntu:24.04 as deploy

ENV DEBIAN_FRONTEND=noninteractive

ARG CMAKE_VERSION
ENV CC=/usr/bin/aarch64-linux-gnu-gcc
ENV CXX=/usr/bin/aarch64-linux-gnu-g++
ENV GOOGLE_TEST_VERSION=v1.17.x
ENV MARCH=armv8-a
CMD ["/bin/bash"]

RUN apt update
RUN apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu git zip unzip wget sudo qemu-user make
RUN apt upgrade -y

COPY --from=cmake-build /opt/cmake-${CMAKE_VERSION} /opt/cmake-${CMAKE_VERSION}
COPY --from=libuuid-build /opt /opt

RUN ln -s /opt/cmake-${CMAKE_VERSION}/bin/cmake /usr/bin/cmake
RUN cp -r /opt/include/* /usr/include
RUN ln -s /opt/lib/libuuid.so /usr/lib
RUN ln -s /opt/lib/libuuid.so.1 /usr/lib

RUN echo '#!/bin/sh' > /usr/local/bin/qemu-aarch64
RUN echo 'exec /usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu "$@"' >> /usr/local/bin/qemu-aarch64
RUN chmod +x /usr/local/bin/qemu-aarch64

RUN git clone https://github.com/google/googletest -b ${GOOGLE_TEST_VERSION}
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest
