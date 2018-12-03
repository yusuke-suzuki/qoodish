FROM ruby:2.5.3-alpine3.8
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

ENV PORT 8080
EXPOSE $PORT
CMD ["bundle", "exec", "puma"]
