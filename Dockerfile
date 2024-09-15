FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV PYTHON_MAJOR_VERSION=13
ENV PYTHON_MINOR_VERSION=0
ENV PYTHON_DEVELOPMENT_STAGE=rc2
ENV PYTHON_VERSION=3.${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}${PYTHON_DEVELOPMENT_STAGE}
CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake gcc g++ valgrind uuid-dev git zip unzip wget sudo dotnet-sdk-8.0
RUN apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev tk-dev
RUN apt update
RUN apt upgrade -y
RUN apt autoremove

RUN git clone https://github.com/google/googletest -b v1.14.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest

RUN wget https://github.com/python/cpython/archive/refs/tags/v${PYTHON_VERSION}.zip
RUN unzip v${PYTHON_VERSION}.zip -d python_source
RUN cd python_source/cpython-${PYTHON_VERSION} && ./configure --enable-optimizations --with-lto --with-computed-gotos --disable-gil --with-mimalloc && make altinstall
RUN update-alternatives --install /usr/bin/python3 python3 $(readlink -f $(which python3)) 0
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.${PYTHON_MAJOR_VERSION} 1
RUN python3 -m pip install --upgrade pip
RUN rm -rf v${PYTHON_VERSION}.zip
RUN rm -rf python_source
