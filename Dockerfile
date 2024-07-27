FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV PYTHON_VERSION=3.12.4

CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake gcc g++ valgrind uuid-dev git zip unzip wget sudo dotnet-sdk-8.0
RUN apt install -y libbz2-dev libncursesw5-dev libgdbm-dev liblzma-dev libsqlite3-dev tk-dev uuid-dev libreadline-dev
RUN apt update
RUN apt upgrade -y
RUN apt autoremove

RUN git clone https://github.com/google/googletest -b v1.14.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest

RUN wget https://github.com/python/cpython/archive/refs/tags/v${PYTHON_VERSION}.zip
RUN unzip v${PYTHON_VERSION}.zip -d python_source
RUN cd python_source/cpython-${PYTHON_VERSION} && ./configure --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi && make altinstall -j $(nproc)
RUN python3 -m pip install --upgrade pip
RUN rm -rf v${PYTHON_VERSION}.zip
RUN rm -rf python_source
