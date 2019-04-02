FROM ruby:2.6.2

RUN mkdir /qoodish
WORKDIR /qoodish

COPY Gemfile /qoodish/Gemfile
COPY Gemfile.lock /qoodish/Gemfile.lock

RUN gem install bundler:2.0.1 && \
      bundle install --jobs=4

COPY . /qoodish
