FROM ruby:2.4.2
RUN mkdir /qoodish
WORKDIR /qoodish
ADD Gemfile /qoodish/Gemfile
ADD Gemfile.lock /qoodish/Gemfile.lock
RUN bundle install
ADD . /qoodish
