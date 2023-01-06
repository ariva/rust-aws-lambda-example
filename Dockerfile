# syntax=docker/dockerfile:experimental

FROM ubuntu:18.04 as cargo-build
ARG name
ARG target
ARG linker

RUN apt-get update && apt-get install -y curl build-essential zip netcat libssl-dev
RUN apt-get install musl-tools -y

# install toolchain
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain 1.65.0 -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup target add ${target}

WORKDIR /usr/src/${name}
COPY Cargo.toml Cargo.toml
RUN mkdir src/
RUN echo "fn main() {panic!(\"if you see this, the build broke\")}" > src/main.rs
RUN --mount=type=ssh export ${linker}; cargo build --features with-lambda --release --target=${target}

RUN rm src/main.rs
COPY src/* src
RUN touch src/**
RUN --mount=type=ssh export ${linker}; cargo test --features with-lambda --release --target=${target}
RUN --mount=type=ssh export ${linker}; cargo build --features with-lambda --release --target=${target}

FROM ubuntu:18.04
ARG name
ARG target
COPY --from=cargo-build /usr/src/${name}/target/${target}/release/${name} /usr/local/bin/${name}
