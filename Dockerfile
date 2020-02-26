FROM google/cloud-sdk:282.0.0-alpine AS cloud-sdk
FROM ruby:2.6.5-alpine3.10

RUN apk add --no-cache \
      mysql-dev \
      tzdata \
      python \
      git \
      build-base \
      libxml2-dev \
      libxslt-dev \
      libc6-compat && \
      ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 && \
      gem install bundler:2.1.4

COPY --from=cloud-sdk /google-cloud-sdk /google-cloud-sdk
ENV PATH /google-cloud-sdk/bin:$PATH
VOLUME ["/root/.config"]

RUN mkdir /qoodish
WORKDIR /qoodish

COPY Gemfile /qoodish/Gemfile
COPY Gemfile.lock /qoodish/Gemfile.lock

RUN rm -rf tmp/cache && \
      CFLAGS="-Wno-cast-function-type" \
      BUNDLE_FORCE_RUBY_PLATFORM=1 \
      bundle install --jobs=4

COPY . /qoodish
