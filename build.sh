#!/usr/bin/env bash

# This script builds a docker image and copies the binary and zip to the current directory to be used by AWS lambda.
# It will use the docker image from the registry if it is available, otherwise it will build the image locally.
# It also autodetects if the host is an M1 mac and sets the target to the correct architecture.
# If you want musl build, set ENV var: MUSL_LINKER=true
#
# 2023-01-05: Tested on M1 mac and x86_64 linux - Linux Mint 20.x or MacOS 12.5.1

set -e
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

COMPANY_NAME="my-company"
CONTAINER_NAME=$(cat Cargo.toml | grep "name" | head -n 1 | sed -E 's/name = "(.*)"/\1/')
DOCKER_NAME="$COMPANY_NAME/$CONTAINER_NAME"
MUSL_LINKER=$(if [ -z $MUSL_LINKER ]; then echo "false"; else echo $MUSL_LINKER; fi)

if [[ $MUSL_LINKER == true ]];
then
  LINKER="RUSTFLAGS=-Clinker=musl-gcc"
  TARGET_TYPE="musl"
else
  LINKER=""
  TARGET_TYPE="gnu"
fi
echo "LINKER: $LINKER"

HOST_CPU=$(uname -m)
echo "HOST_CPU: $HOST_CPU"

# Default x86-64 linux target:
TARGET="x86_64-unknown-linux-gnu"

if [[ $HOST_CPU == 'arm64' ]]; then
  echo "M1"
  TARGET="aarch64-unknown-linux-$TARGET_TYPE"
fi
if [[ $HOST_CPU == 'x86_64' ]]; then
  echo "x86_64"
  TARGET="x86_64-unknown-linux-$TARGET_TYPE"
fi

# Uncomment the target you want override the target:
# TARGET="aarch64-unknown-linux-gnu"
# TARGET="x86_64-unknown-linux-musl"

# if we are not in a build, pull the image
if [ -z $BUILD_ID ];
then
  TAG=$DOCKER_NAME
  SSH="--ssh default"
else
  TAG="our.private.docker.registry/$DOCKER_NAME"
  SSH="--ssh default=/home/ci/.ssh/id_rsa"
fi

DOCKER_BUILDKIT=1 docker build $SSH --cache-from $TAG --build-arg "name=$CONTAINER_NAME" --build-arg "target=$TARGET" --build-arg "linker=$LINKER" --build-arg "BUILDKIT_INLINE_CACHE=1" -t $TAG .
docker run -v $DIR:/dist --rm --entrypoint cp $TAG "/usr/local/bin/$CONTAINER_NAME" /dist/bootstrap

# if we are not in a build, push the image
if [ -z $BUILD_ID ]; then
  echo "Not pushing image, we are not in a build."
else
  docker push $TAG
fi

zip lambda.zip bootstrap
# rm bootstrap
