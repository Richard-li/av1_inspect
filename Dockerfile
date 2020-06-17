FROM ubuntu:18.04

ENV \ 
	GPG_SERVERS="ha.pool.sks-keyservers.net hkp://p80.pool.sks-keyservers.net:80 keyserver.ubuntu.com hkp://keyserver.ubuntu.com:80 pgp.mit.edu"

# install base build dependencies and useful packages
RUN \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse"           >/etc/apt/sources.list && \
	echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >>/etc/apt/sources.list && \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse"  >>/etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		#autoconf \
		#automake \
		#build-essential \
		cmake \
		git-core \
		#cmake-extras \
		#openjdk-8-jdk-headless \
		#python2.7 \
		#vim \
		#wget \
		#yasm \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists

# install emscripten
ENV \
	EMSDK_DIR=/opt/emsdk

RUN \
	EMSDK_VERSION=sdk-1.39.16-64bit && \
	for server in $(shuf -e ${GPG_SERVERS}) ; do \
		http_proxy= gpg --keyserver "$server" --recv-keys 0527A9B7 && break || : ; \
	done && \
	git clone https://github.com/emscripten-core/emsdk.git ${EMSDK_DIR} && \
	cd /opt/emsdk && \
	./emsdk install ${EMSDK_VERSION} && \
	./emsdk activate ${EMSDK_VERSION}

# fetch LibAom source code
ENV \
    LIBAOM_DIR=/opt/libaom

RUN \
    git clone https://github.com/edmond-zhu/aom.git ${LIBAOM_DIR}

# EMSDK Compilation
RUN \
    cd /tmp && \
    mkdir buildAnalyzer && \
    cd buildAnalyzer && \
    cmake /opt/libaom \
        -DENABLE_CCACHE=1 \
        -DAOM_TARGET_CPU=generic \
        -DENABLE_DOCS=0 \
        -DENABLE_TESTS=0 \
        -DCONFIG_ACCOUNTING=1 \
        -DCONFIG_INSPECTION=1 \
        -DCONFIG_MULTITHREAD=0 \
        -DCONFIG_RUNTIME_CPU_DETECT=0 \
        -DCONFIG_WEBM_IO=0 \
		-DCMAKE_BUILD_TYPE=release \
        -DAOM_EXTRA_C_FLAGS="-std=gnu99" \
        -DAOM_EXTRA_CXX_FLAGS="-std=gnu++11" \
        -DCMAKE_TOOLCHAIN_FILE=${EMSDK_DIR}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake && \
	make inspect && \
    #cp ./examples/*

