FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV PYTHON_VERSION=3.12.4

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
RUN cd python_source/cpython-${PYTHON_VERSION} && ./configure --enable-optimizations --with-lto --with-computed-gotos && make altinstall
RUN ln -s /usr/local/bin/python3.12 /usr/bin/python
RUN python -m pip install --upgrade pip
RUN rm -rf v${PYTHON_VERSION}.zip
RUN rm -rf python_source
