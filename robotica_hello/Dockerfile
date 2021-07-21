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
WORKDIR /opt/app

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

# This builds the dependancies
COPY robotica_common/mix.exs robotica_common/mix.lock /opt/robotica_common/
COPY robotica_hello/mix.exs robotica_hello/mix.lock /opt/app/
RUN mix deps.get --only prod

COPY robotica_common/config /opt/robotica_common/config/
COPY robotica_common/lib /opt/robotica_common/lib/
COPY robotica_hello/config /opt/app/config/
RUN mix deps.compile

# This step builds assets for the Phoenix app (if there is one)
COPY robotica_hello/assets /opt/app/assets/
RUN \
  cd /opt/app/assets && \
  npm install && \
  npm run deploy && \
  cd .. && \
  mix phx.digest;

# Setup access to version information
ARG BUILD_DATE=date
ARG VCS_REF=vcs
ENV BUILD_DATE=${BUILD_DATE}
ENV VCS_REF=${VCS_REF}

COPY robotica_hello/lib /opt/app/lib/
COPY robotica_hello/priv /opt/app/priv/
RUN mix compile
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
COPY --from=builder /opt/app/_build .
RUN chown -R app: ./prod
USER app

CMD ["./prod/rel/robotica_hello/bin/robotica_hello", "start"]
