FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13

CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake gcc g++ valgrind uuid-dev python3 python3-pip python3-venv git zip unzip wget sudo dotnet-sdk-8.0 snapd
RUN snap install flutter
RUN apt update
RUN apt upgrade -y
RUN apt autoremove

RUN git clone https://github.com/google/googletest -b v1.14.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest
