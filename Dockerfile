FROM ubuntu:18.04

# environment variables
ENV \
	APP_USER=xiph \
	APP_DIR=/opt/app \
	LC_ALL=C.UTF-8 \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	DEBIAN_FRONTEND=noninteractive \
	GPG_SERVERS="ha.pool.sks-keyservers.net hkp://p80.pool.sks-keyservers.net:80 keyserver.ubuntu.com hkp://keyserver.ubuntu.com:80 pgp.mit.edu"

# add runtime user
RUN \
	groupadd --gid 1000 ${APP_USER} && \
	useradd --uid 1000 --gid ${APP_USER} --shell /bin/bash --create-home ${APP_USER}

# install base build dependencies and useful packages
RUN \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse"           >/etc/apt/sources.list && \
	echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >>/etc/apt/sources.list && \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse"  >>/etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		build-essential \
		bzip2 \
		ca-certificates \
		check \
		cmake \
		cmake-extras \
		curl \
		dirmngr \
		file \
		gettext-base \
		git-core \
		gpg \
		gpg-agent \
		iproute2 \
		iputils-ping \
		jq \
		less \
		libicu-dev \
		libjpeg-dev \
		libogg-dev \
		libpng-dev \
		libtool \
		locales \
		nasm \
		netcat-openbsd \
		net-tools \
		openjdk-8-jdk-headless \
		openssl \
		pkg-config \
		procps \
		psmisc \
		python2.7 \
		rsync \
		runit \
		sqlite3 \
		strace \
		tcpdump \
		tzdata \
		unzip \
		uuid \
		vim \
		wget \
		xz-utils \
		yasm \
		cargo \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists

# set working directory
WORKDIR ${APP_DIR}

# install node 8.x
RUN \
	NODE_VERSION=8.12.0 && \
	ARCH=x64 && \
	for key in \
		94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
		FD3A5288F042B6850C66B31F09FE44734EB7990E \
		71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
		DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
		C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
		B9AE9905FFD7803F25714661B63B535A4C206CA9 \
		56730D5401028683275BD23C23EFEFE93C4CFFFE \
		77984A986EBC2AA786BC0F66B01FBB92821C587A \
		8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
	; do \
		for server in $(shuf -e ${GPG_SERVERS}) ; do \
			http_proxy= gpg --keyserver "$server" --recv-keys "${key}" && break || : ; \
		done ; \
	done && \
	curl -fSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" && \
	curl -fSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc" && \
	gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc && \
	grep " node-v${NODE_VERSION}-linux-${ARCH}.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
	tar xJf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -C /usr --strip-components=1 --no-same-owner && \
	rm -vf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt && \
	ln -s /usr/bin/node /usr/bin/nodejs

# install emscripten
ENV \
	EMSDK_DIR=/opt/emsdk

RUN \
	EMSDK_VERSION=sdk-1.39.16-64bit && \
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

