FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV FLUTTER_VERSION=3.22.2
ENV PATH=${PATH}:/usr/bin/flutter

CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake gcc g++ valgrind uuid-dev python3 python3-pip python3-venv git zip unzip wget sudo dotnet-sdk-8.0
RUN apt install -y curl xz-utils libglu1-mesa libgtk-3-dev libstdc++-12-dev
RUN apt update
RUN apt upgrade -y
RUN apt autoremove

RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
RUN tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /usr/bin/
RUN rm -rf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

RUN git clone https://github.com/google/googletest -b v1.14.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest
