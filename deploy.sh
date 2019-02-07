#!/usr/bin/env sh

SERVICE=steem

[ ! -z "${STEEM_BUILD_TYPE}" ] || STEEM_BUILD_TYPE=Release
[ ! -z "${STEEM_STATIC_BUILD}" ] || STEEM_STATIC_BUILD=ON
[ ! -z "${STEEM_SMT_SUPPORT}" ] || STEEM_SMT_SUPPORT=OFF
[ ! -z "${STEEM_STD_ALLOCATOR_SUPPORT}" ] || STEEM_STD_ALLOCATOR_SUPPORT=OFF
[ ! -z "${STEEM_LOW_MEMORY_NODE}" ] || STEEM_LOW_MEMORY_NODE=OFF
[ ! -z "${STEEM_CLEAR_VOTES}" ] || STEEM_CLEAR_VOTES=OFF
[ ! -z "${STEEM_SKIP_BY_TX_ID}" ] || STEEM_SKIP_BY_TX_ID=OFF
[ ! -z "${STEEM_TESTNET}" ] || STEEM_TESTNET=OFF
[ ! -z "${STEEM_CHAINBASE_CHECK_LOCKING}" ] || STEEM_CHAINBASE_CHECK_LOCKING=OFF
[ ! -z "${STEEM_THREADS_BUILD}" ] || STEEM_THREADS_BUILD="`nproc`"
[ ! -z "${STEEM_USER}" ] || STEEM_USER="${SERVICE}d"
[ ! -z "${STEEM_HOME}" ] || STEEM_HOME="/var/lib/${SERVICE}d"
[ ! -z "${STEEM_P2P_PORT}" ] || STEEM_P2P_PORT=8231
[ ! -z "${STEEM_RPC_HTTP_PORT}" ] || STEEM_RPC_HTTP_PORT=8090
[ ! -z "${STEEM_RPC_WS_PORT}" ] || STEEM_RPC_WS_PORT=8090
[ ! -z "${STEEM_DOCKER_HOST}" ] || STEEM_DOCKER_HOST=unix:///var/run/docker.sock

WORKTREE="`dirname \`realpath \"${0}\"\``"
SERVICE_REPO="${SUDO_USER}/${PROJECT}_${SERVICE}"
STAGE0="${SERVICE_REPO}_stage0"
STAGE1="${SERVICE_REPO}_stage1"
STEEM_GIT_TAG="`cd \"${WORKTREE}\" && git describe --long --tags --dirty`"
STAGE2="${SERVICE_REPO}:${STEEM_GIT_TAG}"
STAGE_LATEST="${SERVICE_REPO}:latest"
DIRTY="`cd \"${WORKTREE}\" && git status -s`"
STEEM_FC_GIT_REVISION_SHA="`cd \"${WORKTREE}/libraries/fc\" && git rev-parse HEAD`"
STEEM_FC_GIT_REVISION_UNIX_TIMESTAMP="`cd \"${WORKTREE}/libraries/fc\" && \
                                       git show -s --format=%ct HEAD`"
STEEM_GIT_REVISION_SHA="`cd \"${WORKTREE}\" && git rev-parse HEAD`"
STEEM_GIT_REVISION_UNIX_TIMESTAMP="`cd \"${WORKTREE}\" && \
                                    git show -s --format=%ct HEAD`"

mkdir \
    -p \
    "${WORKTREE}/build" \
    "${WORKTREE}/install" && \
chown \
    -R \
    "${SUDO_UID}:${SUDO_GID}" \
    "${WORKTREE}/build" \
    "${WORKTREE}/install" && \
([ -z "${DIRTY}" ] && [ ! "${STEEM_FORCE_BUILD}" -eq "1" ] && buildah inspect "${STAGE2}" > /dev/null 2> /dev/null || \
 ([ -z "${DIRTY}" ] && [ ! "${STEEM_FORCE_BUILD}" -eq "1" ] && buildah inspect "${STAGE1}" > /dev/null 2> /dev/null || \
  ((buildah inspect "${STAGE0}" > /dev/null 2> /dev/null || \
    buildah from \
        --name "${STAGE0}" \
        ubuntu:xenial) && \
   buildah run \
       "${STAGE0}" \
       /usr/bin/env \
           sh -c -- \
              "apt update && \
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
                   perl" && \
   buildah run \
       --user "${SUDO_UID}:${SUDO_GID}" \
       -v "${WORKTREE}:/usr/src/${SERVICE}:ro" \
       -v "${WORKTREE}/libraries/fc/vendor/secp256k1-zkp/autom4te.cache:/usr/src/${SERVICE}/libraries/fc/vendor/secp256k1-zkp/autom4te.cache:rw" \
       -v "${WORKTREE}/libraries/fc/vendor/secp256k1-zkp/src/libsecp256k1-config.h.in:/usr/src/${SERVICE}/libraries/fc/vendor/secp256k1-zkp/src/libsecp256k1-config.h.in:rw" \
       -v "${WORKTREE}/build:/usr/build/${SERVICE}" \
       -v "${WORKTREE}/install:/usr/local/${SERVICE}" \
       "${STAGE0}" \
       /usr/bin/env \
           sh -c -- \
              "cd \"/usr/build/${SERVICE}\" && \
               cmake \
                   -DCMAKE_BUILD_TYPE=\"${STEEM_BUILD_TYPE}\" \
                   -DCMAKE_INSTALL_PREFIX=\"/usr/local/${SERVICE}\" \
                   -DFC_GIT_REVISION_SHA=\"${STEEM_FC_GIT_REVISION_SHA}\" \
                   -DFC_GIT_REVISION_UNIX_TIMESTAMP=\"${STEEM_FC_GIT_REVISION_UNIX_TIMESTAMP}\" \
                   -DSTEEM_GIT_REVISION_SHA=\"${STEEM_GIT_REVISION_SHA}\" \
                   -DSTEEM_GIT_REVISION_UNIX_TIMESTAMP=\"${STEEM_GIT_REVISION_UNIX_TIMESTAMP}\" \
                   -DSTEEM_GIT_REVISION_DESCRIPTION=\"${STEEM_GIT_TAG}\" \
                   -DSTEEM_STATIC_BUILD=\"${STEEM_STATIC_BUILD}\" \
                   -DENABLE_SMT_SUPPORT=\"${STEEM_SMT_SUPPORT}\" \
                   -DENABLE_STD_ALLOCATOR_SUPPORT=\"${STEEM_STD_ALLOCATOR_SUPPORT}\" \
                   -DLOW_MEMORY_NODE=\"${STEEM_LOW_MEMORY_NODE}\" \
                   -DCLEAR_VOTES=\"${STEEM_CLEAR_VOTES}\" \
                   -DSKIP_BY_TX_ID=\"${STEEM_SKIP_BY_TX_ID}\" \
                   -BUILD_STEEM_TESTNET=\"${STEEM_TESTNET}\" \
                   -DCHAINBASE_CHECK_LOCKING=\"${STEEM_CHAINBASE_CHECK_LOCKING}\" \
                   \"../../src/${SERVICE}\" && \
               make -j\"${STEEM_THREADS_BUILD}\" && \
               make -j\"${STEEM_THREADS_BUILD}\" install" && \
   (buildah inspect "${STAGE1}" > /dev/null 2> /dev/null || \
    buildah from \
        --name "${STAGE1}" \
        ubuntu:xenial)) && \
   buildah config \
       -u root \
       "${STAGE1}" && \
   buildah run \
       -v "${WORKTREE}/install:/usr/install/${SERVICE}:ro" \
       -v "${STEEM_CONFIG}:/usr/install-data/${SERVICE}/etc/config.ini:ro" \
       "${STAGE1}" \
       /usr/bin/env \
           -u USER \
           -u HOME \
           sh -c -- \
              "apt update && \
               apt upgrade -y && \
               apt install -y libreadline6 && \
               mkdir \
                   -p \
                   \"/usr/local/${SERVICE}/bin\" \
                   \"/usr/local/${SERVICE}/etc\" && \
               cp \
                   -R \
                   \"/usr/install/${SERVICE}/bin/\"* \
                   \"/usr/local/${SERVICE}/bin\" && \
               cp \
                   \"/usr/install-data/${SERVICE}/etc/config.ini\" \
                   \"/usr/local/${SERVICE}/etc/config.ini\" && \
               adduser \
                   --system \
                   --home \"${STEEM_HOME}\" \
                   --shell /bin/bash \
                   --group \
                   --disabled-password \
                   \"${STEEM_USER}\" && \
               mkdir -p \"/var/cache/${SERVICE}d\" && \
               chown \
                   \"${STEEM_USER}:${STEEM_USER}\" \
                   \"/var/cache/${SERVICE}d\"" && \
   buildah config \
       -e USER="${STEEM_USER}" \
       -e HOME="${STEEM_HOME}" \
       -e PATH="/usr/local/${SERVICE}/sbin:/usr/local/${SERVICE}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
       -e STEEM_P2P_PORT="${STEEM_P2P_PORT}" \
       -e STEEM_RPC_HTTP_PORT="${STEEM_RPC_HTTP_PORT}" \
       -e STEEM_RPC_WS_PORT="${GOLOS_RPC_WS_PORT}" \
       -e STEEM_CONFIG="/usr/local/${SERVICE}/etc/config.ini" \
       --cmd \
           "\"/usr/local/${SERVICE}/bin/${SERVICE}d\" \
                --config=\"/usr/local/${SERVICE}/etc/config.ini\" \
                --data-dir=\"${STEEM_HOME}\" \
                --p2p-endpoint=\"0.0.0.0:${STEEM_P2P_PORT}\" \
                --webserver-http-endpoint=\"0.0.0.0:${STEEM_RPC_HTTP_PORT}\" \
                --webserver-ws-endpoint=\"0.0.0.0:${STEEM_RPC_WS_PORT}\"" \
       -p "${STEEM_P2P_PORT}" \
       -p "${STEEM_RPC_HTTP_PORT}" \
       -p "${STEEM_RPC_WS_PORT}" \
       -u "${STEEM_USER}" \
       -v "${STEEM_HOME}" \
       --workingdir "${STEEM_HOME}" \
       "${STAGE1}" && \
   buildah commit \
       "${STAGE1}" \
       "${STAGE2}" &&
   buildah tag \
       "${STAGE2}" \
       "${STAGE_LATEST}" &&
   buildah push \
       --dest-daemon-host "${STEEM_DOCKER_HOST}" \
       "${STAGE2}" \
       "docker-daemon:${STAGE2}" &&
   docker \
       -H "${STEEM_DOCKER_HOST}" \
       tag \
           "${STAGE2}" \
           "${STAGE_LATEST}"))
