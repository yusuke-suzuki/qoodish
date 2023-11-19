FROM ruby:3.2

WORKDIR /qoodish

COPY Gemfile /qoodish/Gemfile
COPY Gemfile.lock /qoodish/Gemfile.lock

RUN bundle install --jobs=4

COPY . /qoodish

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 8080

CMD puma
