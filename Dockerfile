FROM ubuntu:xenial as builder

ARG STEEM_BUILD_TYPE=Release
ARG STEEM_STATIC_BUILD=ON
ARG STEEM_SMT_SUPPORT=OFF
ARG STEEM_STD_ALLOCATOR_SUPPORT=OFF
ARG STEEM_LOW_MEMORY_NODE=OFF
ARG STEEM_CLEAR_VOTES=OFF
ARG STEEM_SKIP_BY_TX_ID=OFF
ARG STEEM_TESTNET=OFF
ARG STEEM_CHAINBASE_CHECK_LOCKING=OFF
ARG STEEM_THREADS_BUILD=1

RUN \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        gcc \
        g++ \
        make \
        autoconf \
        cmake \
        zlib1g-dev \
        libbz2-dev \
        libsnappy-dev \
        libreadline-dev \
        libncurses-dev \
        libssl-dev \
        libboost-chrono-dev \
        libboost-context-dev \
        libboost-coroutine-dev \
        libboost-date-time-dev \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-locale-dev \
        libboost-program-options-dev \
        libboost-serialization-dev \
        libboost-signals-dev \
        libboost-system-dev \
        libboost-test-dev \
        libboost-thread-dev \
        python3 \
        python3-jinja2 \
        doxygen \
        perl \
        git

COPY . /usr/local/src/steem

RUN \
    cd /usr/local/src/steem && \
    export STEEM_GIT_REVISION_SHA="`git rev-parse HEAD`" && \
    export STEEM_GIT_REVISION_UNIX_TIMESTAMP="`git show -s --format=%ct HEAD`" && \
    cd libraries/fc && \
    export STEEM_FC_GIT_REVISION_SHA="`git rev-parse HEAD`" && \
    export STEEM_FC_GIT_REVISION_UNIX_TIMESTAMP="`git show -s --format=%ct HEAD`" && \
    mkdir -p /usr/local/build/steem && \
    cd /usr/local/build/steem && \
    cmake \
        -DCMAKE_BUILD_TYPE="${STEEM_BUILD_TYPE}" \
        -DCMAKE_INSTALL_PREFIX=/usr/local/steem \
        -DFC_GIT_REVISION_SHA="${STEEM_FC_GIT_REVISION_SHA}" \
        -DFC_GIT_REVISION_UNIX_TIMESTAMP="${STEEM_FC_GIT_REVISION_UNIX_TIMESTAMP}" \
        -DSTEEM_GIT_REVISION_SHA="${STEEM_GIT_REVISION_SHA}" \
        -DSTEEM_GIT_REVISION_UNIX_TIMESTAMP="${STEEM_GIT_REVISION_UNIX_TIMESTAMP}" \
        -DSTEEM_GIT_REVISION_DESCRIPTION="${STEEM_GIT_TAG}" \
        -DSTEEM_STATIC_BUILD="${STEEM_STATIC_BUILD}" \
        -DENABLE_SMT_SUPPORT="${STEEM_SMT_SUPPORT}" \
        -DENABLE_STD_ALLOCATOR_SUPPORT="${STEEM_STD_ALLOCATOR_SUPPORT}" \
        -DLOW_MEMORY_NODE="${STEEM_LOW_MEMORY_NODE}" \
        -DCLEAR_VOTES="${STEEM_CLEAR_VOTES}" \
        -DSKIP_BY_TX_ID="${STEEM_SKIP_BY_TX_ID}" \
        -BUILD_STEEM_TESTNET="${STEEM_TESTNET}" \
        -DCHAINBASE_CHECK_LOCKING="${STEEM_CHAINBASE_CHECK_LOCKING}" \
        ../../src/steem && \
    make -j"${STEEM_THREADS_BUILD}" && \
    make -j"${STEEM_THREADS_BUILD}" install

FROM ubuntu:xenial

ARG STEEM_P2P_PORT=8231
ARG STEEM_RPC_HTTP_PORT=8090
ARG STEEM_RPC_WS_PORT=8090
ENV \
    STEEM_P2P_PORT="${STEEM_P2P_PORT}" \
    STEEM_RPC_HTTP_PORT="${STEEM_RPC_HTTP_PORT}" \
    STEEM_RPC_WS_PORT="${STEEM_RPC_WS_PORT}"

RUN \
    apt update && \
    apt upgrade -y && \
    apt install -y libreadline6 && \
    adduser \
        --system \
        --home /var/lib/steemd \
        --shell /bin/bash \
        --group \
        --disabled-password \
        steemd && \
    mkdir -p /var/cache/steemd && \
    chown -R \
        steemd:steemd \
        /var/cache/steemd

COPY \
    --from=builder \
    /usr/local/steem \
    /usr/local/steem

USER steemd

ENV PATH="/usr/local/steem/sbin:/usr/local/steem/bin:${PATH}"

VOLUME /var/lib/steemd

WORKDIR /var/lib/steemd

EXPOSE ${STEEM_P2P_PORT}/tcp
EXPOSE ${STEEM_RPC_HTTP_PORT}/tcp
EXPOSE ${STEEM_RPC_WS_PORT}/tcp

CMD \
    steemd \
        --config="/usr/local/steem/etc/config.ini" \
        --data-dir=/var/lib/steemd \
        --p2p-endpoint="0.0.0.0:${STEEM_P2P_PORT}" \
        --webserver-http-endpoint="0.0.0.0:${STEEM_RPC_HTTP_PORT}" \
        --webserver-ws-endpoint="0.0.0.0:${STEEM_RPC_WS_PORT}"