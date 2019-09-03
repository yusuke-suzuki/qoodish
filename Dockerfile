FROM google/cloud-sdk:261.0.0-alpine AS cloud-sdk
FROM ruby:2.6.4

RUN apt update && apt install -y python

COPY --from=cloud-sdk /google-cloud-sdk /google-cloud-sdk
ENV PATH /google-cloud-sdk/bin:$PATH
VOLUME ["/root/.config"]

RUN mkdir /qoodish
WORKDIR /qoodish

COPY Gemfile /qoodish/Gemfile
COPY Gemfile.lock /qoodish/Gemfile.lock

RUN gem install bundler:2.0.1 && \
      bundle install --jobs=4

COPY . /qoodish
