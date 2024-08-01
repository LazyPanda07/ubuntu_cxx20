FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_VERSION=android-34
ENV SDK_INSTALL_NAME=platforms;android-34
ENV NDK_VERSION=27.0.12077973
ENV NDK_INSTALL_NAME=ndk;27.0.12077973
ENV FLUTTER_VERSION=3.22.3

ENV NDK_PATH=/Android/Sdk/ndk/${NDK_VERSION}
ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++

CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake python3 python3-pip python3-venv git zip unzip wget sudo dotnet-sdk-8.0 openjdk-17-jdk clang ninja-build pkg-config libgtk-3-dev
RUN apt upgrade -y
RUN apt autoremove

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip
RUN unzip tools.zip
RUN rm -rf tools.zip
RUN mkdir latest && cd cmdline-tools && mv * ../latest/ && mv ../latest . && cd .. && mkdir -p Android/Sdk && mv cmdline-tools Android/Sdk && cd Android/Sdk/cmdline-tools/latest/bin && yes | ./sdkmanager --licenses && ./sdkmanager "${NDK_INSTALL_NAME}" && ./sdkmanager --install "${NDK_INSTALL_NAME}" && ./sdkmanager --list | grep ndk

RUN git clone https://github.com/google/googletest -b v1.14.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest

RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
RUN tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /usr/local/bin/
RUN rm -rf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

ENV PATH=${PATH}:/usr/local/bin/flutter/bin:/Android/Sdk:/Android/Sdk/cmdline-tools:/Android/Sdk/platforms:/Android/Sdk/cmdline-tools/latest/bin:/Android/Sdk/platforms/${ANDROID_VERSION}

RUN sdkmanager ${SDK_INSTALL_NAME}
RUN git config --global --add safe.directory /usr/local/bin/flutter
RUN flutter config --android-sdk /Android/Sdk
RUN flutter --version
RUN flutter doctor -v
