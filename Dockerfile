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

FROM ubuntu:24.04 as deploy

ENV DEBIAN_FRONTEND=noninteractive

ARG CMAKE_VERSION
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV PYTHON_MAJOR_VERSION=13
ENV PYTHON_MINOR_VERSION=5
ENV PYTHON_DEVELOPMENT_STAGE=
ENV GOOGLE_TEST_VERSION=v1.17.x
ENV PYTHON_VERSION=3.${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}${PYTHON_DEVELOPMENT_STAGE}
CMD ["/bin/bash"]

RUN apt update
RUN apt install -y gcc g++ valgrind uuid-dev git zip unzip wget sudo dotnet-sdk-8.0
RUN apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev tk-dev
RUN apt update
RUN apt upgrade -y
RUN apt autoremove

COPY --from=cmake-build /opt/cmake-${CMAKE_VERSION} /opt/cmake-${CMAKE_VERSION}

RUN ln -s /opt/cmake-${CMAKE_VERSION}/bin/cmake /usr/bin/cmake

RUN git clone https://github.com/google/googletest -b ${GOOGLE_TEST_VERSION}
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest

RUN wget https://github.com/python/cpython/archive/refs/tags/v${PYTHON_VERSION}.zip
RUN unzip v${PYTHON_VERSION}.zip -d python_source
RUN cd python_source/cpython-${PYTHON_VERSION} && ./configure --enable-optimizations --with-lto --with-computed-gotos --disable-gil --with-mimalloc && make altinstall
RUN update-alternatives --install /usr/bin/python3 python3 $(readlink -f $(which python3)) 0
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.${PYTHON_MAJOR_VERSION} 1
RUN update-alternatives --install /usr/bin/pip3 pip3 /usr/local/bin/pip3.${PYTHON_MAJOR_VERSION} 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
RUN python3 -m pip install --upgrade pip
RUN rm -rf v${PYTHON_VERSION}.zip
RUN rm -rf python_source
