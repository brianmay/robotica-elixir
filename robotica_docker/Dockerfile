# The version of Alpine to use for the final image
# This should match the version of Alpine that the `elixir:1.7.2-alpine` image uses
ARG ALPINE_VERSION=3.14

FROM elixir:1.12-alpine AS builder

# The version of the application we are building (required)
ARG APP_VSN=0.1.0
# The environment to build with
ARG MIX_ENV=prod
# Set this to true if this release is not a Phoenix app
ENV APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV} \
    BUILD_WITHOUT_QUIC=true

# By convention, /opt is typically used for applications
WORKDIR /opt/robotica_docker

# This step installs all the build tools we'll need
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
    nodejs \
    npm \
    git \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

# This installs the dependancies
COPY robotica_common/mix.exs robotica_common/mix.lock /opt/robotica_common/
COPY robotica_face/mix.exs robotica_face/mix.lock /opt/robotica_face/
COPY robotica/mix.exs robotica/mix.lock /opt/robotica/
COPY robotica_docker/mix.exs robotica_docker/mix.lock /opt/robotica_docker/
RUN mix deps.get --only prod

# This builds the dependancies
COPY robotica_common/config /opt/robotica_common/config/
COPY robotica_common/lib /opt/robotica_common/lib/
COPY robotica_face/config /opt/robotica_face/config/
COPY robotica_face/lib /opt/robotica_face/lib/
COPY robotica/config /opt/robotica/config/
COPY robotica/lib /opt/robotica/lib/
COPY robotica_docker/config /opt/robotica_docker/config/
COPY robotica_docker/lib /opt/robotica_docker/lib/
RUN mix deps.compile

# Build phoenix stuff
# Note mix phx.digest won't work unless app is compiled.
# We compile in test to reduce the external dependancies required.
COPY config/*.sample /opt/config/
RUN cd /opt/robotica_face && MIX_ENV=test mix deps.get
RUN cd /opt/robotica_face && MIX_ENV=test mix compile
COPY robotica_face/assets /opt/robotica_face/assets/
RUN \
  cd /opt/robotica_face/assets && \
  npm install && \
  npm run deploy && \
  cd .. && \
  MIX_ENV=test mix phx.digest;

# Setup access to version information
ARG BUILD_DATE=date
ARG VCS_REF=vcs
ENV BUILD_DATE=${BUILD_DATE}
ENV VCS_REF=${VCS_REF}

RUN mix compile
COPY robotica_docker/rel /opt/robotica_docker/rel/
RUN mix release

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:${ALPINE_VERSION}

RUN apk update && \
    apk add --no-cache \
      bash \
      openssl-dev \
      libstdc++

RUN addgroup -S app && adduser -S app -G app
WORKDIR /opt/app
COPY --from=builder /opt/robotica_docker/_build .
RUN chown -R app: ./prod
USER app

CMD ["./prod/rel/robotica_docker/bin/robotica_docker", "start"]
