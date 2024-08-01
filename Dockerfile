FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_VERSION=android-34
ENV SDK_INSTALL_NAME=platforms;android-34
ENV NDK_VERSION=27.0.12077973
ENV NDK_INSTALL_NAME=ndk;27.0.12077973
ENV FLUTTER_VERSION=3.22.3

CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake python3 python3-pip python3-venv git zip unzip wget sudo dotnet-sdk-8.0 openjdk-17-jdk
RUN apt update
RUN apt upgrade -y
RUN apt autoremove

RUN git clone https://github.com/google/googletest -b v1.14.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest

ENV NDK_PATH=/Android/Sdk/ndk/${NDK_VERSION}
ENV CC=${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-${ANDROID_VERSION}-clang
ENV CXX=${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-${ANDROID_VERSION}-clang++

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip
RUN unzip tools.zip
RUN rm -rf tools.zip
RUN shopt -s extglob && cd cmdline-tools && mkdir latest && mv !(latest) latest/ && cd .. && mkdir -p Android/Sdk && mv cmdline-tools Android/Sdk && cd Android/Sdk/cmdline-tools/latest/bin && yes | ./sdkmanager --licenses && ./sdkmanager "${NDK_INSTALL_NAME}" && ./sdkmanager --install "${NDK_INSTALL_NAME}" && ./sdkmanager --list | grep ndk

RUN https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
RUN tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /usr/bin/
RUN rm -rf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

ENV PATH=${PATH}:/usr/bin/flutter/bin
