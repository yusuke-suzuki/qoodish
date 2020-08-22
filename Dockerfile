FROM ruby:2.6.6-alpine3.12

RUN apk add --no-cache \
      less \
      mysql-dev \
      tzdata \
      git \
      build-base \
      libxml2-dev \
      libxslt-dev \
      libc6-compat && \
      ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 && \
      gem install bundler:2.1.4

WORKDIR /qoodish

COPY Gemfile /qoodish/Gemfile
COPY Gemfile.lock /qoodish/Gemfile.lock

RUN rm -rf tmp/cache && \
      CFLAGS="-Wno-cast-function-type" \
      BUNDLE_FORCE_RUBY_PLATFORM=1 \
      bundle install --jobs=4

COPY . /qoodish

COPY --from=asia-docker.pkg.dev/berglas/berglas/berglas:latest /bin/berglas /bin/berglas

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 8080

CMD bundle exec rails db:migrate && bundle exec puma
