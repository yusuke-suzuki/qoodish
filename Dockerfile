FROM ruby:2.5.1-alpine3.7
RUN mkdir /qoodish
WORKDIR /qoodish
ADD Gemfile /qoodish/Gemfile
ADD Gemfile.lock /qoodish/Gemfile.lock
RUN apk add --no-cache \
      mysql-dev \
      tzdata
RUN apk add --no-cache --virtual=.build-dependencies \
      git \
      build-base \
      libxml2-dev \
      libxslt-dev && \
    bundle install && \
    apk del .build-dependencies
ADD . /qoodish
