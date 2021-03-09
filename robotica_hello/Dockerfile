# The version of Alpine to use for the final image
# This should match the version of Alpine that the `elixir:1.7.2-alpine` image uses
ARG ALPINE_VERSION=3.13

FROM elixir:1.11-alpine AS builder

# The version of the application we are building (required)
ARG APP_VSN=0.1.0
# The environment to build with
ARG MIX_ENV=prod
# Set this to true if this release is not a Phoenix app
ENV APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

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
COPY robotica_plugins/mix.exs robotica_plugins/mix.lock /opt/robotica_plugins/
COPY robotica_hello/mix.exs robotica_hello/mix.lock /opt/app/
RUN mix deps.get --only prod

COPY robotica_plugins/lib /opt/robotica_plugins/lib/
COPY robotica_plugins/dummy.yaml /opt/robotica_plugins/
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

WORKDIR /opt/app
COPY robotica_hello/lib /opt/app/lib/
COPY robotica_hello/priv /opt/app/priv/
RUN mix compile
RUN mix release

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:${ALPINE_VERSION}

RUN apk update && \
    apk add --no-cache \
      bash \
      openssl-dev

RUN addgroup -S app && adduser -S app -G app
WORKDIR /opt/app
COPY --from=builder /opt/app/_build .
RUN chown -R app: ./prod
USER app

CMD ["./prod/rel/robotica_hello/bin/robotica_hello", "start"]
