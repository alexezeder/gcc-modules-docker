FROM debian:buster-slim AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        bzip2 \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        g++ \
        make \
        flex \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone \
        -b devel/c++-modules \
        --single-branch --depth 1 \
        https://github.com/gcc-mirror/gcc.git \
        gcc-source \
        && \
    mkdir gcc-build && \
    cd gcc-build && \
    ../gcc-source/configure \
        --enable-languages=c,c++ \
        --disable-gcov \
        --disable-multilib \
        --disable-libada \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --disable-libgomp \
        --disable-libvtv \
        --disable-werror \
        --disable-nls \
        --disable-lto \
        && \
    make STAGE1_CFLAGS='-O2' BOOT_CFLAGS='-O2' -j`nproc` > build_log.txt || (tail -500 build_log.txt; exit 1) && \
    make install && \
    cd .. && \
    rm -rf gcc-source gcc-build

FROM debian:buster-slim
COPY --from=build /usr/local/ /usr/local/

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        make \
        binutils \
        libc-dev \
        libmpc3 \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '1s/^/\/usr\/local\/lib64\n/' /etc/ld.so.conf && \
    ldconfig -v
