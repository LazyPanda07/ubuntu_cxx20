ARG CMAKE_VERSION=4.2.1

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

FROM ubuntu:24.04 AS deploy

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/lib":${PATH}
ENV LD_LIBRARY_PATH="/usr/lib/dotnet/host/fxr/8.0.21/":${LD_LIBRARY_PATH}

ARG CMAKE_VERSION
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV PYTHON_MAJOR_VERSION=3
ENV PYTHON_MINOR_VERSION=14
ENV PYTHON_PATCH=2
ENV PYTHON_DEVELOPMENT_STAGE=
ENV BOOST_VERSION=1.89.0
ENV BOOST_TAG=boost-${BOOST_VERSION}
ENV PYTHON_VERSION=${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}.${PYTHON_PATCH}${PYTHON_DEVELOPMENT_STAGE}
CMD ["/bin/bash"]

RUN apt update
RUN apt install -y gcc g++ valgrind uuid-dev git zip unzip wget sudo dotnet-sdk-8.0 ninja-build netcat-openbsd
RUN apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev tk-dev
RUN apt update
RUN apt upgrade -y

RUN wget https://github.com/python/cpython/archive/refs/tags/v${PYTHON_VERSION}.zip
RUN unzip v${PYTHON_VERSION}.zip -d python_source
RUN cd python_source/cpython-${PYTHON_VERSION} && ./configure --enable-shared --enable-optimizations --with-lto --with-computed-gotos && make -j $(nproc) && make altinstall
RUN update-alternatives --install /usr/bin/python3 python3 $(readlink -f $(which python3)) 0
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION} 1
RUN update-alternatives --install /usr/bin/pip3 pip3 /usr/local/bin/pip${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION} 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
RUN echo "/usr/local/lib" | tee /etc/ld.so.conf.d/python${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}.conf
RUN ldconfig
RUN python3 -m pip install --upgrade pip
RUN rm -rf v${PYTHON_VERSION}.zip
RUN rm -rf python_source

COPY --from=cmake-build /opt/cmake-${CMAKE_VERSION} /opt/cmake-${CMAKE_VERSION}

RUN ln -s /opt/cmake-${CMAKE_VERSION}/bin/cmake /usr/bin/cmake

RUN git clone https://github.com/boostorg/boost.git -b ${BOOST_TAG} --recursive
RUN cd boost && mkdir build && cd build && cmake -DBOOST_STACKTRACE_ENABLE_BACKTRACE=ON .. && cmake --build . -j && cmake --install .
RUN rm -rf boost
