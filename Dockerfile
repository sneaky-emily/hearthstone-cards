FROM ruby:3.0.4 AS base
RUN groupadd -g 4242 sinatra && adduser --system --uid 4242 --ingroup sinatra sinatra
USER sinatra

FROM base AS dependencies
WORKDIR /sinatra/
COPY --chown=4242:4242 Gemfile Gemfile.lock /sinatra/
RUN bundle config set --local without 'test development'
RUN gem install bundler:2.3.14
RUN bundle install

FROM dependencies AS app
WORKDIR /sinatra/
USER sinatra
ENV APP_HOME /sinatra/
ADD --chown=4242:4242 .. $APP_HOME
CMD ["bundle", "exec", "rackup", "-E", "production", "-p", "8000", "--host", "0.0.0.0"]

