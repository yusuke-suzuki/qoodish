FROM ruby:3.0.1

WORKDIR /qoodish

COPY Gemfile /qoodish/Gemfile
COPY Gemfile.lock /qoodish/Gemfile.lock

RUN gem install bundler:2.1.4 && bundle install --jobs=4

COPY . /qoodish

COPY --from=asia-docker.pkg.dev/berglas/berglas/berglas:latest /bin/berglas /bin/berglas

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 8080

CMD bundle exec rails db:migrate && bundle exec puma
