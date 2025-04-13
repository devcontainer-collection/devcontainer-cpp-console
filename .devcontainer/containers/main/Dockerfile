FROM rockylinux:9.3

RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf update -y

RUN dnf groupinstall -y "Development Tools"

## curl is conflicting with curl-minimal
## curl-minimal is installed by default in Rocky Linux 9
## dnf is depending on curl-minimal so we can't remove it. use curl-minimal instead
RUN dnf install -y \
    clang \
    lld \
    llvm \
    cmake \
    git \
    # curl \ 
    file \
    unzip \
    nano \
    pkgconf-pkg-config \
    openssl-devel \
    zlib-devel \
    glibc-devel.i686 \
    libstdc++-devel.i686 \
    mingw64-gcc \
    binutils-aarch64-linux-gnu \
    && dnf clean all

# mingw64-gcc \ # to install x86_64-w64-mingw32-strip
# mingw64-gcc-c++ \
# mingw64-winpthreads \
# mingw64-headers\


# ----- install strip tools -----
ARG BINUTILS_VERSION=2.44
# Download binutils source code
RUN mkdir -p /tmp/binutils-src && cd /tmp/binutils-src && \
    curl -LO https://ftp.kaist.ac.kr/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz && \
    tar -xf binutils-${BINUTILS_VERSION}.tar.gz
# Build and install aarch64-w64-mingw32-strip for Windows ARM64 (PE/COFF) binaries
RUN cd /tmp/binutils-src && \
    mkdir build-aarch64-w64 && cd build-aarch64-w64 && \
    ../binutils-${BINUTILS_VERSION}/configure \
    --target=aarch64-w64-mingw32 \
    --prefix=/opt/binutils-aarch64-w64 \
    --disable-multilib && \
    make -j$(nproc) && \
    make install
# Add aarch64-w64-mingw32-strip to PATH
ENV PATH="/opt/binutils-aarch64-w64/bin:$PATH"
# Build and install x86_64-linux-gnu-strip for Linux x86_64 (ELF) binaries
RUN cd /tmp/binutils-src && \
    mkdir build-x86_64-linux && cd build-x86_64-linux && \
    ../binutils-${BINUTILS_VERSION}/configure \
    --target=x86_64-linux-gnu \
    --prefix=/opt/binutils-x86_64-linux \
    --disable-multilib && \
    make -j$(nproc) && \
    make install
# Add x86_64-linux-gnu-strip to PATH
ENV PATH="/opt/binutils-x86_64-linux/bin:$PATH"
# Cleanup
RUN rm -rf /tmp/binutils-src
# ===== intall strip tools =====

# install zig
RUN curl -LO https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz && \
    tar -xf zig-linux-x86_64-0.14.0.tar.xz && \
    mv zig-linux-x86_64-0.14.0 /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig && \
    rm zig-linux-x86_64-0.14.0.tar.xz


WORKDIR /workspace

CMD ["tail", "-f", "/dev/null"]
