ARG CMAKE_VERSION=4.2.3

FROM ubuntu:24.04 AS cmake-build

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

FROM ubuntu:24.04 AS libuuid-build

ENV DEBIAN_FRONTEND=noninteractive

ENV CC=/usr/bin/aarch64-linux-gnu-gcc
ENV CXX=/usr/bin/aarch64-linux-gnu-g++

RUN apt update
RUN apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu git zip unzip wget sudo make
RUN apt install -y autoconf autopoint automake gettext flex bison libtool netcat-openbsd

WORKDIR /tmp

RUN git clone https://github.com/util-linux/util-linux.git
RUN cd util-linux && ./autogen.sh && ./configure --host=aarch64-linux-gnu --prefix=/opt --disable-all-programs --enable-libuuid && make && make install

FROM ubuntu:24.04 AS deploy

ENV DEBIAN_FRONTEND=noninteractive

ARG CMAKE_VERSION
ENV CC=/usr/bin/aarch64-linux-gnu-gcc
ENV CXX=/usr/bin/aarch64-linux-gnu-g++
ENV MARCH=armv8-a
CMD ["/bin/bash"]

RUN apt update
RUN apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu git zip unzip wget sudo qemu-user make ninja-build curl redis-server python3 python3-pip
RUN apt upgrade -y

RUN wget -q "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt update
RUN apt install -y powershell
RUN rm -rf packages-microsoft-prod.deb

COPY --from=cmake-build /opt/cmake-${CMAKE_VERSION} /opt/cmake-${CMAKE_VERSION}
COPY --from=libuuid-build /opt /opt

RUN ln -s /opt/cmake-${CMAKE_VERSION}/bin/cmake /usr/bin/cmake
RUN cp -r /opt/include/* /usr/include
RUN ln -s /opt/lib/libuuid.so /usr/lib
RUN ln -s /opt/lib/libuuid.so.1 /usr/lib

RUN echo '#!/bin/sh' > /usr/local/bin/qemu-aarch64
RUN echo 'exec /usr/bin/qemu-aarch64 -L /usr/aarch64-linux-gnu "$@"' >> /usr/local/bin/qemu-aarch64
RUN chmod +x /usr/local/bin/qemu-aarch64
