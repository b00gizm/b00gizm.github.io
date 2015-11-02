FROM ruby:2.0.0

RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y nodejs
RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock

RUN bundle install

ADD . /app

EXPOSE 4000