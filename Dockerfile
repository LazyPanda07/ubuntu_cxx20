FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_VERSION=android-35
ENV SDK_INSTALL_NAME=platforms;android-35
ENV BUILD_TOOLS_NAME=build-tools;35.0.0
ENV NDK_VERSION=27.2.12479018
ENV NDK_INSTALL_NAME=ndk;27.2.12479018
ENV FLUTTER_VERSION=3.24.3
ENV FLUTTER_PATH=/opt/flutter
ENV FLUTTER_BIN_PATH=${FLUTTER_PATH}/bin

ENV NDK_PATH=/Android/Sdk/ndk/${NDK_VERSION}
ENV ANDROID_NDK_ROOT=${NDK_PATH}
ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++

CMD ["/bin/bash"]

RUN apt update
RUN apt install -y cmake python3 python3-pip python3-venv git zip unzip wget sudo dotnet-sdk-8.0 openjdk-21-jdk clang ninja-build pkg-config libgtk-3-dev
RUN apt upgrade -y
RUN apt autoremove

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip
RUN unzip tools.zip
RUN rm -rf tools.zip
RUN mkdir latest && cd cmdline-tools && mv * ../latest/ && mv ../latest . && cd .. && mkdir -p Android/Sdk && mv cmdline-tools Android/Sdk && cd Android/Sdk/cmdline-tools/latest/bin && yes | ./sdkmanager --licenses && ./sdkmanager "${NDK_INSTALL_NAME}" && ./sdkmanager --install "${NDK_INSTALL_NAME}" && ./sdkmanager --list | grep ndk

RUN git clone https://github.com/google/googletest -b v1.15.x
RUN cd googletest && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make install -j $(nproc)
RUN rm -rf googletest

RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
RUN tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt/
RUN rm -rf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

ENV ANDROID_HOME=/Android/Sdk
ENV PATH=${FLUTTER_BIN_PATH}:${ANDROID_HOME}:${ANDROID_HOME}/cmdline-tools:${ANDROID_HOME}/platforms:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platforms/${ANDROID_VERSION}:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}

RUN sdkmanager "platform-tools" "${SDK_INSTALL_NAME}" "${BUILD_TOOLS_NAME}"

RUN git config --system --add safe.directory /opt/flutter
RUN flutter config --android-sdk ${ANDROID_HOME}
RUN flutter --version
RUN flutter doctor -v
