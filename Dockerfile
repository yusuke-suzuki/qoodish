FROM ruby:2.6.1-alpine3.8
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
      bundle install
ADD . /qoodish
