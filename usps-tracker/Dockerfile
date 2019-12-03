ARG BUILD_FROM
FROM $BUILD_FROM

ENV APP_ENV production

ENV LANG C.UTF-8

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler

# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    rm -rf /var/cache/apk/*

RUN mkdir /usr/app
WORKDIR /usr/app

RUN gem install bundler:1.17.3 --no-rdoc --no-ri

COPY Gemfile /usr/app/
COPY Gemfile.lock /usr/app/
RUN bundle install

COPY . /usr/app

CMD [ "bundle", "exec", "ruby", "server.rb", "-p", "9005" ]
